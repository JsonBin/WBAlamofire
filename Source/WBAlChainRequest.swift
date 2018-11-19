//
//  WBAlChainRequest.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/30.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation

///  WBAlChainRequest can be used to chain several WBAlBaseRequest so that one
///  will only starts after another finishes. Note that when used inside WBAlChainRequest,
///  a single WBAlBaseRequest will have its own callback and delegate cleared, in favor
///  of the batch request callback.
public final class WBAlChainRequest {

    public typealias WBAlChainRequestClosure = (_ chainRequest: WBAlChainRequest, _ baseRequest: WBAlBaseRequest) -> Void
  
// MARK: - Public Properties
    
///=============================================================================
/// @name Public Properties
///=============================================================================
    
    /// 所有的请求数组
    ///  All the requests are stored in this array.
    public private(set) var requests: [WBAlBaseRequest]
    
    /// 响应delegate
    ///  The delegate object of the chain request. Default is nil.
    public weak var delegate: WBAlChainRequestProtocol?
    
    /// 网络请求的协议组
    ///  This can be used to add several accossories object. Note if you use `add(_ requestAccessory:)` to add acceesory
    ///  this array will be automatically created. Default is nil.
    public private(set) var requestAccessories: [WBAlRequestAccessoryProtocol]?

// MARK: - Private Properties
    
///=============================================================================
/// @name Private Properties
///=============================================================================

    private let emptyCallBack: WBAlChainRequestClosure
    private var requestCallBacks: [WBAlChainRequestClosure]
    private var nextRequestIndex: Int
    /// unique identifier.
    public private(set) var rawString: String
    
// MARK: - Cycle Life
    
///=============================================================================
/// @name Cycle Life
///=============================================================================
    
    public init() {
        nextRequestIndex = 0
        requests = [WBAlBaseRequest]()
        requestCallBacks = [WBAlChainRequestClosure]()
        emptyCallBack = { _, _ in }
        rawString = UUID().uuidString
    }
    
// MARK: - Start Action
    
///=============================================================================
/// @name Start Action
///=============================================================================
    
    ///  Start the chain request, adding first request in the chain to request queue.
    public func start() {
        if nextRequestIndex > 0 {
            WBAlog("Chain Error! Chain request has already started!")
            return
        }
        if !requests.isEmpty {
            self.totalAccessoriesWillStart()
            
            self.startNextRequest()
            WBAlChainAlamofire.shared.add(self)
        } else {
            WBAlog("Chain Error! Chain requests is empty!")
        }
    }
    
    ///  Stop the chain request. Remaining request in chain will be cancelled.
    public func stop() {
        self.totalAccessoriesWillStop()
        self.delegate = nil
        self.cleanRequest()
        WBAlChainAlamofire.shared.remove(self)
        
        self.totalAccessoriesDidStop()
    }

    /// Add request to request chain.
    ///
    /// - Parameters:
    ///   - request: The request to be chained.
    ///   - closure: The finish callback
    public func add(_ request: WBAlBaseRequest, callBack closure: WBAlChainRequestClosure? = nil) {
        requests.append(request)
        if let closure = closure {
            requestCallBacks.append(closure)
        } else {
            requestCallBacks.append(emptyCallBack)
        }
    }
    
    ///  Convenience method to add request accessory. See also `requestAccessories`.
    public func add(_ requestAccessory: WBAlRequestAccessoryProtocol) {
        if requestAccessories == nil {
            requestAccessories = [WBAlRequestAccessoryProtocol]()
        }
        requestAccessories?.append(requestAccessory)
    }
    
// MARK: - Private
    
///=============================================================================
/// @name Private
///=============================================================================
    
    @discardableResult private func startNextRequest() -> Bool {
        if nextRequestIndex < requests.count {
            let request = requests[nextRequestIndex]
            nextRequestIndex += 1
            request.delegate = self
            request.clearCompleteClosure()
            request.start()
            return true
        }
        return false
    }
    
    private func cleanRequest() -> Void {
        let currentIndex = nextRequestIndex - 1
        if currentIndex <  requests.count {
            let request = requests[currentIndex]
            request.stop()
        }
        requests.removeAll()
        requestCallBacks.removeAll()
    }
}

// MARK: - WBAlRequestAccessoryProtocol

///=============================================================================
/// @name WBAlRequestAccessoryProtocol
///=============================================================================

extension WBAlChainRequest {
    
    func totalAccessoriesWillStart() -> Void {
        requestAccessories?.forEach {
            $0.requestWillStart(self)
        }
    }
    
    func totalAccessoriesWillStop() -> Void {
        requestAccessories?.forEach {
            $0.requestWillStop(self)
        }
    }
    
    func totalAccessoriesDidStop() -> Void {
        requestAccessories?.forEach {
            $0.requestDidStop(self)
        }
    }
}


// MARK: - Request Protocol

///=============================================================================
/// @name Request Protocol
///=============================================================================

extension WBAlChainRequest : WBAlRequestProtocol {
    
    public func requestFinish(_ request: WBAlBaseRequest) {
        let currentIndex = nextRequestIndex - 1
        let closure = requestCallBacks[currentIndex]
        closure(self, request)
        if !self.startNextRequest() {
            self.totalAccessoriesWillStop()
            
            if let delegate = delegate {
                delegate.chainRequestDidFinished(self)
                WBAlChainAlamofire.shared.remove(self)
            }
            self.totalAccessoriesDidStop()
        }
    }
    
    public func requestFailed(_ request: WBAlBaseRequest) {
        self.totalAccessoriesWillStop()
        if let delegate = delegate {
            delegate.chainRequestDidFailed(self, failedBaseRequest: request)
            WBAlChainAlamofire.shared.remove(self)
        }
        
        self.totalAccessoriesDidStop()
    }
}

// MARK: - WBAlChainRequestProtocol

///=============================================================================
/// @name WBAlChainRequestProtocol
///=============================================================================

///  The WBAlChainRequestProtocol protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue. Note the delegate methods will be called when all the requests
///  of chain request finishes.
public protocol WBAlChainRequestProtocol : class {
    
    /// Tell the delegate that the chain request has finished successfully.
    /// 链式响所有请求应成功的回调
    ///
    /// - Parameter chainRequest: The corresponding chain request.
    func chainRequestDidFinished(_ chainRequest: WBAlChainRequest) -> Void
    
    /// Tell the delegate that the chain request has failed.
    /// 响应失败触发回调
    ///
    /// - Parameters:
    ///   - chainRequest: The corresponding chain request.
    ///   - request: First failed request that causes the whole request to fail.
    func chainRequestDidFailed(_ chainRequest: WBAlChainRequest, failedBaseRequest request: WBAlBaseRequest) -> Void
}

extension WBAlChainRequestProtocol {
    public func chainRequestDidFinished(_ chainRequest: WBAlChainRequest) -> Void {}
    
    public func chainRequestDidFailed(_ chainRequest: WBAlChainRequest, failedBaseRequest request: WBAlBaseRequest) -> Void {}
}

// MARK: - WBAlChainAlamofire

///=============================================================================
/// @name WBAlChainAlamofire
///=============================================================================

///  WBAlChainAlamofire handles chain request management. It keeps track of all
///  the chain requests.
public final class WBAlChainAlamofire {
    
    ///  Get the shared chain request.
    public static let shared = WBAlChainAlamofire()
    
// MARK: - Private Properties
    
///=============================================================================
/// @name Private Properties
///=============================================================================
    
    private let lock: NSLock
    private var chainRequests: [WBAlChainRequest]
    
// MARK: - Cycle Life
    
///=============================================================================
/// @name Cycle Life
///=============================================================================
    
    public init() {
        lock = NSLock()
        chainRequests = [WBAlChainRequest]()
    }
    
// MARK: - Public
    
///=============================================================================
/// @name Public
///=============================================================================
    
    ///  Add a chain request.
    public func add(_ chainRequest: WBAlChainRequest) {
        lock.lock()
        defer { lock.unlock() }
        chainRequests.append(chainRequest)
    }
    
    ///  Remove a previously added chain request.
    public func remove(_ chainRequest: WBAlChainRequest) {
        lock.lock()
        defer { lock.unlock() }
        let index = chainRequests.index(where: { $0 == chainRequest })
        if let index = index {
            chainRequests.remove(at: index)
        }
    }
}

extension WBAlChainRequest : Equatable {}

/// Overloaded operators
public func ==(
    lhs: WBAlChainRequest,
    rhs: WBAlChainRequest)
    -> Bool
{
    return lhs.rawString == rhs.rawString
}

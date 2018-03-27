//
//  WBAlBatchRequest.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/31.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation

///  WBAlBatchRequest can be used to batch several WBAlRequest. Note that when
///  used inside WBAlBatchRequest, a single WBAlRequest will have its own callback
///  and delegate cleared, in favor of the batch request callback.
public final class WBAlBatchRequest {
    
    public typealias WBAlBatchRequestClosure = (_ batchRequest: WBAlBatchRequest) -> Void

// MARK: - Public Properties
    
///=============================================================================
/// @name Public Properties
///=============================================================================

    /// 所有的并列请求.
    ///  All the requests are stored in this array.
    public private(set) var requests: [WBAlRequest]
    
    /// 响应delegate
    ///  The delegate object of the batch request. Default is nil.
    public weak var delegate: WBAlBatchRequestProtocol?
    
    /// 网络请求的协议组
    ///  This can be used to add several accossories object. Note if you use `add(_ requestAccessory)` to add acceesory
    ///  this array will be automatically created. Default is nil.
    public private(set) var requestAccessories: [WBAlRequestAccessoryProtocol]?
    
    /// 如果请求失败, 此为失败的请求
    ///  The first request that failed (and causing the batch request to fail).
    public private(set) var failedRequest: WBAlRequest?
    
    ///  batch request identify. Default 0.
    ///  Tag can be used to identify batch request. Default value is 0.
    public var tag: Int
    
    /// 请求成功回调
    ///  The success callback. Note this will be called only if all the requests are finished.
    ///  This block will be called on the main queue.
    public var successCompleteClosure: WBAlBatchRequestClosure?
    
    /// 请求失败回调
    ///  The failure callback. Note this will be called if one of the requests fails.
    ///  This block will be called on the main queue.
    public var failureCompleteClosure: WBAlBatchRequestClosure?
    
    /// 数据源是否全部来自于缓存
    ///  Whether all response data is from local cache.
    public var isDataFromCache: Bool {
        var dataCache = true
        requests.forEach {
            if !$0.isDataFromCache { dataCache = false }
        }
        return dataCache
    }
    
// MARK: - Private Properties
    
///=============================================================================
/// @name Private Properties
///=============================================================================

    fileprivate var _finishCount: Int
    public private(set) var rawString: String
    
// MARK: - Cycle Life
    
///=============================================================================
/// @name Cycle Life
///=============================================================================
    
    /// Creates a `WBAlBatchRequest` with a bunch of requests.
    ///
    /// - Parameter WBAlRequests: requests useds to create batch request.
    public init(WBAlRequests: [WBAlRequest] ) {
        requests = WBAlRequests
        _finishCount = 0
        tag = 0
        rawString = UUID().uuidString
    }
    
// MARK: - Start Action
    
///=============================================================================
/// @name Start Action
///=============================================================================
    
    ///  Append all the requests to queue.
    public func start() -> Void {
        if _finishCount > 0 {
            WBALog("Batch Error! batch request has already started.")
            return
        }
        self.failedRequest = nil
        WBAlBatchAlamofire.shared.add(self)
        self.totalAccessoriesWillStart()
        for request in requests {
            request.delegate = self
            request.clearCompleteClosure()
            request.start()
        }
    }
    
    ///  Stop all the requests of the batch request.
    public func stop() -> Void {
        self.totalAccessoriesWillStop()
        self.delegate = nil
        self.cleanRequest()
        
        self.totalAccessoriesDidStop()
        WBAlBatchAlamofire.shared.remove(self)
    }
    
    ///  Convenience method to start the batch request with block callbacks.
    public func start(_ success: WBAlBatchRequestClosure?, failure failureClosure: WBAlBatchRequestClosure?) {
        self.successCompleteClosure = success
        self.failureCompleteClosure = failureClosure
        
        self.start()
    }
    
    ///  Convenience method to add request accessory. See also `requestAccessories`.
    public func add(_ requestAccessory: WBAlRequestAccessoryProtocol) {
        if requestAccessories == nil {
            requestAccessories = [WBAlRequestAccessoryProtocol]()
        }
        requestAccessories?.append(requestAccessory)
    }
    
    ///  Set completion callbacks
    public func set(_ success: WBAlBatchRequestClosure?, failure failureClosure: WBAlBatchRequestClosure?) {
        self.successCompleteClosure = success
        self.failureCompleteClosure = failureClosure
    }
    
    ///  Nil out both success and failure callback blocks.
    public func cleanCompleteClosre() -> Void {
        // nil out to break the retain cycle.
        self.successCompleteClosure = nil
        self.failureCompleteClosure = nil
    }
    
// MARK: - Private
    
///=============================================================================
/// @name Private
///=============================================================================
    
    private func cleanRequest() -> Void {
        for request in requests {
            request.stop()
        }
        self.cleanCompleteClosre()
    }
    
    deinit {
        self.cleanRequest()
    }
}

// MARK: - WBAlRequestAccessoryProtocol

///=============================================================================
/// @name WBAlRequestAccessoryProtocol
///=============================================================================

extension WBAlBatchRequest {
    
    func totalAccessoriesWillStart() -> Void {
        if let accessoris = self.requestAccessories {
            for accessory in accessoris {
                accessory.requestWillStart(self)
            }
        }
    }
    
    func totalAccessoriesWillStop() -> Void {
        if let accessoris = self.requestAccessories {
            for accessory in accessoris {
                accessory.requestWillStop(self)
            }
        }
    }
    
    func totalAccessoriesDidStop() -> Void {
        if let accessoris = self.requestAccessories {
            for accessory in accessoris {
                accessory.requestDidStop(self)
            }
        }
    }
}

// MARK: - Request Protocol

///=============================================================================
/// @name Request Protocol
///=============================================================================

extension WBAlBatchRequest : WBAlRequestProtocol {
    
    public func requestFinish(_ request: WBAlBaseRequest) {
        _finishCount += 1
        if _finishCount == requests.count {
            self.totalAccessoriesWillStop()
            
            if let delegate = delegate {
                delegate.batchRequestDidFinished(self)
            }
            if let closure = successCompleteClosure {
                closure(self)
            }
            self.cleanCompleteClosre()
            
            self.totalAccessoriesDidStop()
            WBAlBatchAlamofire.shared.remove(self)
        }
    }
    
    public func requestFailed(_ request: WBAlBaseRequest) {
        self.failedRequest = request as? WBAlRequest
        self.totalAccessoriesWillStop()
        // stop
        for request in requests {
            request.stop()
        }
        // call back
        if let delegate = delegate {
            delegate.batchRequestDidFailed(self)
        }
        if let closure = failureCompleteClosure {
            closure(self)
        }
        // clean
        self.cleanCompleteClosre()
        
        self.totalAccessoriesDidStop()
        WBAlBatchAlamofire.shared.remove(self)
    }
}

// MARK: - WBAlBatchRequestProtocol

///=============================================================================
/// @name WBAlBatchRequestProtocol
///=============================================================================

/// Batch request protocol
///  The WBAlBatchRequestProtocol protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue. Note the delegate methods will be called when all the requests
///  of batch request finishes.
public protocol WBAlBatchRequestProtocol : class {
    
    ///  Tell the delegate that the batch request has finished successfully/
    /// 并式请求响应成功
    ///
    ///  @param batchRequest The corresponding batch request.
    func batchRequestDidFinished(_ batchRequest: WBAlBatchRequest) -> Void
    
    ///  Tell the delegate that the batch request has failed.
    /// 并式请求响应失败
    ///
    ///  @param batchRequest The corresponding batch request.
    func batchRequestDidFailed(_ batchRequest: WBAlBatchRequest) -> Void
}

extension WBAlBatchRequestProtocol {
    public func batchRequestDidFinished(_ batchRequest: WBAlBatchRequest) -> Void{}
    
    public func batchRequestDidFailed(_ batchRequest: WBAlBatchRequest) -> Void{}
}

// MARK: - WBAlBatchAlamofire

///=============================================================================
/// @name WBAlBatchAlamofire
///=============================================================================

///  WBAlBatchAlamofire handles batch request management. It keeps track of all
///  the batch requests.
public final class WBAlBatchAlamofire {
    
    ///  Get the shared batch request.
    public static let shared = WBAlBatchAlamofire()

// MARK: - Private Properties
    
///=============================================================================
/// @name Private Properties
///=============================================================================
    
    private let _lock: NSLock
    private var _batchRequests: [WBAlBatchRequest]
    
// MARK: - Cycle Life
    
///=============================================================================
/// @name Cycle Life
///=============================================================================
    
    public init() {
        _lock = NSLock()
        _batchRequests = [WBAlBatchRequest]()
    }
    
// MARK: - Public
    
///=============================================================================
/// @name Public
///=============================================================================
    
    ///  Add a batch request.
    public func add(_ batchRequest: WBAlBatchRequest) {
        _lock.lock()
        defer { _lock.unlock() }
        _batchRequests.append(batchRequest)
    }
    
    ///  Remove a previously added batch request.
    public func remove(_ batchRequest: WBAlBatchRequest) {
        _lock.lock()
        defer { _lock.unlock() }
        let index = _batchRequests.index(where: { $0 == batchRequest })
        if let index = index {
            _batchRequests.remove(at: index)
        }
    }
}

extension WBAlBatchRequest : Equatable {}

/// Overloaded operators
public func ==(
    lhs: WBAlBatchRequest,
    rhs: WBAlBatchRequest)
    -> Bool
{
    return lhs.rawString == rhs.rawString
}

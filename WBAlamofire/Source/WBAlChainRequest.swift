//
//  WBAlChainRequest.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/30.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation

/// 链式响应网络请求
open class WBAlChainRequest {

    public typealias WBAlChainRequestClosure = (_ chainRequest: WBAlChainRequest, _ baseRequest:WBAlBaseRequest) -> Void
    
    /// 所有的请求数组
    open var requests: [WBAlBaseRequest]
    
    /// 响应delegate
    open weak var delegate: WBAlChainRequestProtocol?
    
    /// 网络请求的协议组
    open var requestAccessories: [WBAlRequestAccessoryProtocol]?
    
    // private properties
    private var _emptyCallBack: WBAlChainRequestClosure
    open private(set) var _requestCallBacks: [WBAlChainRequestClosure]
    open private(set) var _nextRequestIndex: Int
    open private(set) var rawString: String
    
// MARK: - Init
    public init() {
        _nextRequestIndex = 0
        requests = [WBAlBaseRequest]()
        _requestCallBacks = [WBAlChainRequestClosure]()
        _emptyCallBack = { _, _ in }
        
        let uuid_ref = CFUUIDCreate(nil)
        let uuid_string_ref = CFUUIDCreateString(nil, uuid_ref)
        rawString = String(format: "%@", uuid_string_ref as! CVarArg).lowercased()
    }
    
// MARK: - Public
    open func start() {
        if _nextRequestIndex > 0 {
            WBALog("Chain Error! Chain request has already started!")
            return
        }
        if !requests.isEmpty {
            self.totalAccessoriesWillStart()
            
            self.startNextRequest()
            WBAlChainAlamofire.shared.add(self)
        }else{
            WBALog("Chain Error! Chain requests is empty!")
        }
    }
    
    open func stop() {
        self.totalAccessoriesWillStop()
        self.delegate = nil
        self.cleanRequest()
        WBAlChainAlamofire.shared.remove(self)
        
        self.totalAccessoriesDidStop()
    }
    
    open func add(_ request:WBAlBaseRequest, callBack closure: WBAlChainRequestClosure?) {
        requests.append(request)
        if let closure = closure {
            _requestCallBacks.append(closure)
        }else{
            _requestCallBacks.append(_emptyCallBack)
        }
    }
    
    open func add(_ requestAccessory: WBAlRequestAccessoryProtocol) {
        if requestAccessories == nil {
            requestAccessories = [WBAlRequestAccessoryProtocol]()
        }
        requestAccessories?.append(requestAccessory)
    }
    
// MARK: - Private
    @discardableResult open func startNextRequest() -> Bool {
        if _nextRequestIndex < requests.count {
            let request = requests[_nextRequestIndex]
            _nextRequestIndex += 1
            request.delegate = self
            request.clearCompleteClosure()
            request.start()
            return true
        }
        return false
    }
    
    private func cleanRequest() -> Void {
        let currentIndex = _nextRequestIndex - 1
        if currentIndex <  requests.count {
            let request = requests[currentIndex]
            request.stop()
        }
        requests.removeAll()
        _requestCallBacks.removeAll()
    }
}

// MARK: - WBAlRequestAccessoryProtocol
extension WBAlChainRequest {
    
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
extension WBAlChainRequest : WBAlRequestProtocol {
    
    public func requestFinish(_ request: WBAlBaseRequest) {
        let currentIndex = _nextRequestIndex - 1
        let closure = _requestCallBacks[currentIndex]
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

/// Chain request protocol
public protocol WBAlChainRequestProtocol : class {
    
    /// 链式响所有请求应成功的回调
    ///
    /// - Parameter chainRequest: WBAlChainRequest
    func chainRequestDidFinished(_ chainRequest: WBAlChainRequest) -> Void
    
    /// 响应失败触发回调
    ///
    /// - Parameters:
    ///   - chainRequest: 当前的链式响应
    ///   - request: 失败触发的请求
    func chainRequestDidFailed(_ chainRequest: WBAlChainRequest, failedBaseRequest request:WBAlBaseRequest) -> Void
}

/// 链式请求管理
open class WBAlChainAlamofire {
    
    /// 实例，唯一
    open static let shared = WBAlChainAlamofire()
    
    // private properties
    private var _lock: NSLock
    private var _chainRequests: [WBAlChainRequest]
    
// MARK: - Init
    public init() {
        _lock = NSLock()
        _chainRequests = [WBAlChainRequest]()
    }
    
// MARK: - Public
    open func add(_ chainRequest: WBAlChainRequest) {
        _lock.lock()
        defer { _lock.unlock() }
        _chainRequests.append(chainRequest)
    }
    
    open func remove(_ chainRequest: WBAlChainRequest) {
        _lock.lock()
        defer { _lock.unlock() }
        let index = _chainRequests.index(where: { $0 == chainRequest })
        if let index = index {
            _chainRequests.remove(at: index)
        }
    }
}
public func ==(
    lhs: WBAlChainRequest,
    rhs: WBAlChainRequest)
    -> Bool
{
    return lhs.rawString == rhs.rawString
}

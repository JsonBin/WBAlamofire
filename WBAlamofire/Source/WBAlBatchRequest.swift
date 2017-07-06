//
//  WBAlBatchRequest.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/31.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation

/// 并式响应网络请求
open class WBAlBatchRequest {
    
    public typealias WBAlBatchRequestClosure = (_ batchRequest: WBAlBatchRequest) -> Void
    
    /// 所有的并列请求
    open var requests: [WBAlRequest]
    
    /// 响应delegate
    open weak var delegate: WBAlBatchRequestProtocol?
    
    /// 网络请求的协议组
    open var requestAccessories: [WBAlRequestAccessoryProtocol]?
    
    /// 如果请求失败, 此为失败的请求
    open var failedRequest: WBAlRequest?
    
    /// batch request identify. Default 0.
    open var tag: Int
    
    /// 请求成功回调
    open var successCompleteClosure: WBAlBatchRequestClosure?
    
    /// 请求失败回调
    open var failureCompleteClosure: WBAlBatchRequestClosure?
    
    /// 数据源是否全部来自于缓存
    open var isDataFromCache: Bool {
        var dataCache = true
        for request in requests {
            if !request.isDataFromCache { dataCache = false }
        }
        return dataCache
    }
    
// MARK: - Private property
    open var _finishCount: Int
    open private(set) var rawString: String
    
// MARK: - Init
    public init(WBAlRequests: [WBAlRequest] ) {
        requests = WBAlRequests
        _finishCount = 0
        tag = 0
        
        let uuid_ref = CFUUIDCreate(nil)
        let uuid_string_ref = CFUUIDCreateString(nil, uuid_ref)
        rawString = String(format: "%@", uuid_string_ref as! CVarArg).lowercased()
        // swift是安全性语言，因此在这里不会涉及其余的类型
        /*for request in requests {
            if request is WBAlRequest {}
            else{
                WBALog("Batch Error! request item must be WBAlRequest instance.")
                return
            }
        }*/
    }
    
// MARK: - Public
    open func start() -> Void {
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
    
    open func stop() -> Void {
        self.totalAccessoriesWillStop()
        self.delegate = nil
        self.cleanRequest()
        
        self.totalAccessoriesDidStop()
        WBAlBatchAlamofire.shared.remove(self)
    }
    
    open func start(_ success: WBAlBatchRequestClosure?, failure failureClosure: WBAlBatchRequestClosure?) {
        self.successCompleteClosure = success
        self.failureCompleteClosure = failureClosure
        
        self.start()
    }
    
    open func add(_ requestAccessory: WBAlRequestAccessoryProtocol) {
        if requestAccessories == nil {
            requestAccessories = [WBAlRequestAccessoryProtocol]()
        }
        requestAccessories?.append(requestAccessory)
    }
    
    open func set(_ success: WBAlBatchRequestClosure?, failure failureClosure: WBAlBatchRequestClosure?) {
        self.successCompleteClosure = success
        self.failureCompleteClosure = failureClosure
    }
    
    open func cleanCompleteClosre() -> Void {
        // nil out to break the retain cycle.
        self.successCompleteClosure = nil
        self.failureCompleteClosure = nil
    }
    
// MARK: - Private
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

/// Batch request protocol
public protocol WBAlBatchRequestProtocol : class {
    
    /// 并式请求响应成功
    ///
    /// - Parameter batchRequest: 成功返回参数
    func batchRequestDidFinished(_ batchRequest: WBAlBatchRequest) -> Void
    
    /// 并式请求响应失败
    ///
    /// - Parameters:
    ///   - batchRequest: 失败响应
    func batchRequestDidFailed(_ batchRequest: WBAlBatchRequest) -> Void
}

/// 并式响应请求管理
open class WBAlBatchAlamofire {
    
    /// 实例，唯一
    open static let shared = WBAlBatchAlamofire()
    
    // private properties
    private var _lock: NSLock
    private var _batchRequests: [WBAlBatchRequest]
    
// MARK: - Init
    public init() {
        _lock = NSLock()
        _batchRequests = [WBAlBatchRequest]()
    }
    
// MARK: - Public
    open func add(_ batchRequest: WBAlBatchRequest) {
        _lock.lock()
        defer { _lock.unlock() }
        _batchRequests.append(batchRequest)
    }
    
    open func remove(_ batchRequest: WBAlBatchRequest) {
        _lock.lock()
        defer { _lock.unlock() }
        let index = _batchRequests.index(where: { $0 == batchRequest })
        if let index = index {
            _batchRequests.remove(at: index)
        }
    }
}

public func ==(
    lhs: WBAlBatchRequest,
    rhs: WBAlBatchRequest)
    -> Bool
{
    return lhs.rawString == rhs.rawString
}

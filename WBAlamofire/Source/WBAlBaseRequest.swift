//
//  WBAlBaseRequest.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/31.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation

/// 请求优先权
///
/// - `default`: 默认
/// - low: 较低
/// - high: 最高
public enum WBALRequestPriority: Int8 {
    case `default` = 0
    case low = -4
    case high = 4
}

/// 请求返回的数据结果类型
///
/// - `default`: 默认
/// - json: JSON
/// - string: String
/// - data: Data
/// - plist: Plist
public enum WBALResponseType: Int8 {
    case `default`, json, string, data, plist
}

/// Request Protoclo
public protocol WBAlRequestProtocol : class {
    
    /// 请求结束
    ///
    /// - Parameter request: WBAlBaseRequest
    func requestFinish(_ request:WBAlBaseRequest) -> Void
    
    /// 请求失败
    ///
    /// - Parameter request: WBAlBaseRequest
    func requestFailed(_ request:WBAlBaseRequest) -> Void
}

/// AlRequest Protocol
public protocol WBAlRequestAccessoryProtocol {
    
    /// 请求即将开始
    ///
    /// - Parameter request: WBAlRequest, WBAlChainRequest, WBAlBatchRequest
    func requestWillStart(_ request: Any) -> Void
    
    /// 请求即将结束
    ///
    /// - Parameter request: WBAlRequest, WBAlChainRequest, WBAlBatchRequest
    func requestWillStop(_ request: Any) -> Void
    
    /// 请求已经结束
    ///
    /// - Parameter request: WBAlRequest, WBAlChainRequest, WBAlBatchRequest
    func requestDidStop(_ request: Any) -> Void
}

public protocol BaseRequest {
    
    /// 上传数据时的closure
    typealias WBAlMutableDataClosure = (_ data:MultipartFormData) -> Void
    
    typealias WBAlRequestCompleteClosure = (_ request:WBAlBaseRequest) -> Void
    
// MARK:  - SubClass Override    
    /// 需要更改baseURL时调用
    var baseURL: String { get }
    
    /// 每一个model请求的url
    var requestURL: String { get }
    
    /// 需要使用cdnURL时调用
    var cdnURL: String { get }
    
    /// 请求的method
    var requestMethod: HTTPMethod { get }
    
    /// 需要添加的请求头
    var requestHeaders: HTTPHeaders? { get }
    
    /// 需要添加的请求参数
    var requestParams: [String: Any]? { get }
    
    /// 请求时param编码
    var paramEncoding: ParameterEncoding { get }
    
    /// 请求返回的数据类型
    var responseType: WBALResponseType { get }
    
    /// 请求的优先权
    var priority: WBALRequestPriority? { get }
    
    // 上传文件时以下面三种任选一种作为上传数据依据
    /// 上传文件时上传的数据
    var requestDataClosure: WBAlMutableDataClosure? { get }
    
    /// 上传文件时文件的url
    var uploadFile: URL? { get }
    
    /// 上传文件时文件的data
    var uploadData: Data? { get }
    
    /// 下载文件保存的名字，默认存放在 .../Documents/downloadCache/...下
    var resumableDownloadPath: String { get }
    
    /// https时使用的证书的用户名以及密码, first is user, last is password.
    var requestAuthHeaders: [String]? { get }
    
    /// 是否使用cdn
    var useCDN: Bool { get }
    
// MARK: - Response Properties
    var statusCode: Int { get }
}

/// 请求baseRequest
open class WBAlBaseRequest : BaseRequest {
    
// MARK:  - SubClass Override
    
    /// 需要更改baseURL时调用
    open var baseURL: String { return "" }
    
    /// 每一个model请求的url
    open var requestURL: String { return "" }
    
    /// 需要使用cdnURL时调用
    open var cdnURL: String { return "" }
    
    /// 请求的method
    open var requestMethod: HTTPMethod { return .get }
    
    /// 需要添加的请求头
    open var requestHeaders: HTTPHeaders? { return nil /*["Content-Type": "application/json", "Accept": "application/json"]*/}
    
    /// 需要添加的请求参数
    open var requestParams: [String: Any]? { return nil }
    
    /// 请求时对参数(params)的编码方式
    open var paramEncoding: ParameterEncoding { return URLEncoding.default }
    
    /// 请求返回的数据类型
    open var responseType: WBALResponseType { return .json }
    
    /// 请求的优先权
    open var priority: WBALRequestPriority? { return nil }
    
    // 上传文件时以下面三种任选一种作为上传数据依据
    /// 上传文件时上传的数据
    open var requestDataClosure: BaseRequest.WBAlMutableDataClosure? { return nil }
    
    /// 上传文件时文件的url
    open var uploadFile: URL? { return nil }
    
    /// 上传文件时文件的data
    open var uploadData: Data? { return nil }
    
    /// 下载文件保存的名字，默认存放在 .../Documents/downloadCache/...下
    open var resumableDownloadPath: String { return "" }
    
    /// https时使用的证书的用户名以及密码, first is user, last is password.
    open var requestAuthHeaders: [String]? { return nil }
    
    /// 是否使用cdn
    open var useCDN: Bool { return false }
    
    /// 是否为需求请求成功状态码的范围内
    open var statusCodeValidator: Bool {
        if WBAlConfig.shared.statusCode.contains(self.statusCode) {
            return true
        }
        return false
    }
    
    /// 过滤请求params的方法, 可覆写. 默认不过滤
    open func cacheFileNameFilterForRequestParams(_ params: [String: Any]) -> [String: Any] { return params }
    
    /// 请求完成成功响应方法 <** 在回到主线程之前的子线程响应，如果是加载的缓存，则一定是在主线程之中响应
    open func requestCompletePreprocessor() -> Void {}
    
    /// 请求完成成功响应方法 <** 在主线程响应
    open func requestCompleteFilter() -> Void {}
    
    /// 请求失败完成响应方法 <** 在回到主线程之前的子线程中响应,可参考 `requestCompletePreprocessor`
    open func requestFailedPreprocessor() -> Void {}
    
    /// 请求失败完成响应方法 <** 在主线程响应
    open func requestFailedFilter() -> Void {}
    
// MARK: - Public Properties
    open weak var delegate: WBAlRequestProtocol?
    
    /// use to request identify, Default 0
    open var tag: Int = 0
    
    /// 网络请求的协议组
    open var requestAccessories: [WBAlRequestAccessoryProtocol]?
    
    /// 下载文件或上传文件的进度
    open var downloadProgress: Request.ProgressHandler?
    
    /// 完成成功的回调
    open var successCompleteClosure: BaseRequest.WBAlRequestCompleteClosure?
    
    /// 完成失败的回调
    open var failureCompleteClosure: BaseRequest.WBAlRequestCompleteClosure?
    
// MARK: - Response Properties
    
    /// 请求完成状态码
    open  var statusCode: Int { return request?.response?.statusCode ?? 500 }
    
    /// 请求状态
    open var state : URLSessionTask.State? { return request?.task?.state }
    
    /// 请求获取的数据
    open var responseData: Data?
    
    /// 请求获取的string(返回类型为Data和String<objc返回为data时也生效>生效)
    open var responseString: String?
    
    /// 默认返回的数据结果
    open var responseObj: Any?
    
    /// 返回为json时请求的结果
    open var responseJson: [String: Any]?
    
    /// 返回为plist时请求的结果
    open var responsePlist: Any?
    
    /// 这是下载专用的url，Default nil.
    open var downloadURL: URL?
    
    /// 请求失败error
    open var error: Error?
    
// MARK: - 私有调用
    open var request: Request?
    
// MARK: - Request Action
    open func start() -> Void {
        self.totalAccessoriesWillStart()
        WBAlamofire.shared.add(self)
    }
    
    open func stop() -> Void {
        self.totalAccessoriesWillStop()
        self.delegate = nil
        WBAlamofire.shared.cancel(self)
        self.totalAccessoriesDidStop()
    }
    
    open func start(_ success: BaseRequest.WBAlRequestCompleteClosure?, failure failureClosure: BaseRequest.WBAlRequestCompleteClosure?) {
        self.set(success, failure: failureClosure)
        
        self.start()
    }
    
    open func set(_ success: BaseRequest.WBAlRequestCompleteClosure?, failure failureClosure: BaseRequest.WBAlRequestCompleteClosure?) {
        self.successCompleteClosure = success
        self.failureCompleteClosure = failureClosure
    }
    
    open func add(_ requestAccessory: WBAlRequestAccessoryProtocol) {
        if requestAccessories == nil {
            requestAccessories = [WBAlRequestAccessoryProtocol]()
        }
        requestAccessories?.append(requestAccessory)
    }
    
    open func clearCompleteClosure() {
        // set nil out to break the retain cycle.
        self.successCompleteClosure = nil
        self.failureCompleteClosure = nil
    }
    
// MARK: - 自定义request
    open var buildCustomRequest: URLRequest? { return nil }
}

// MARK: - WBAlRequestAccessoryProtocol
extension WBAlBaseRequest {
    
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

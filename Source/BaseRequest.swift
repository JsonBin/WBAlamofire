//
//  BaseRequest.swift
//  WBAlamofire
//
//  Created by zwb on 2017/12/27.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation
import Alamofire

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
/// - `default`: 默认 is Data
/// - json: JSON
/// - string: String
/// - data: Data
/// - plist: Plist
public enum WBALResponseType: Int8 {
    case `default`, json, string, data, plist
}

/// 网络请求需要调用的方法
///
/// - options: "OPTIONS"
/// - get: "GET"
/// - head: "HEAD"
/// - post: "POST"
/// - put: "PUT"
/// - patch: "PATCH"
/// - delete: "DELETE"
/// - trace: "TRACE"
/// - connect: "CONNECT"
public enum WBHTTPMethod {
    
    case options, get, head, post, put, patch, delete, trace, connect
    
    public init(rawValue: HTTPMethod) {
        switch rawValue {
        case HTTPMethod.options:  self = .options
        case HTTPMethod.get:      self = .get
        case HTTPMethod.head:     self = .head
        case HTTPMethod.post:     self = .post
        case HTTPMethod.put:      self = .put
        case HTTPMethod.patch:    self = .patch
        case HTTPMethod.delete:   self = .delete
        case HTTPMethod.trace:    self = .trace
        case HTTPMethod.connect:  self = .connect
        }
    }
    
    public var rawValue: HTTPMethod {
        switch self {
        case .options: return HTTPMethod.options
        case .get:     return HTTPMethod.get
        case .head:    return HTTPMethod.head
        case .post:    return HTTPMethod.post
        case .put:     return HTTPMethod.put
        case .patch:   return HTTPMethod.patch
        case .delete:  return HTTPMethod.delete
        case .trace:   return HTTPMethod.trace
        case .connect: return HTTPMethod.connect
        }
    }
}

/// 参数编码方式
///
/// - json: JSONEncoding
/// - url: URLEncoding
/// - plist: PropertyListEncoding
public enum WBParameterEncoding {
    case json, url, plist
    
    public init(rawValue: ParameterEncoding) {
        switch rawValue {
        case is JSONEncoding:
            self = .json
        case is URLEncoding:
            self = .url
        case is PropertyListEncoding:
            self = .plist
        default: self = .url
        }
    }
    
    public var rawValue: ParameterEncoding {
        switch self {
        case .url:   return URLEncoding.default
        case .json:  return JSONEncoding.default
        case .plist: return PropertyListEncoding.default
        }
    }
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

/// 基础协议
public protocol BaseRequest {
    
    /// 上传数据时的closure
    typealias WBAlMutableDataClosure = (_ data:MultipartFormData) -> Void
    
    /// 请求完成closure
    typealias WBAlRequestCompleteClosure = (_ request:WBAlBaseRequest) -> Void
    
    /// A dictionary of headers to apply to a `URLRequest`.
    typealias WBHTTPHeaders = [String: String]
    
// MARK:  - SubClass Override
    /// 需要更改baseURL时调用
    var baseURL: String { get }
    
    /// 每一个model请求的url
    var requestURL: String { get }
    
    /// 需要使用cdnURL时调用
    var cdnURL: String { get }
    
    /// 请求的method
    var requestMethod: WBHTTPMethod { get }
    
    /// 需要添加的请求头
    var requestHeaders: WBHTTPHeaders? { get }
    
    /// 需要添加的请求参数
    var requestParams: [String: Any]? { get }
    
    /// 请求时param编码
    var paramEncoding: WBParameterEncoding { get }
    
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
    
    /// 下载文件保存的名字，默认存放在 .../Documents/{WBAlConfig.shared.downFileName}/...下
    var resumableDownloadPath: String { get }
    
    /// https时使用的证书的用户名以及密码, first is user, last is password.
    var requestAuthHeaders: [String]? { get }
    
    /// 是否使用cdn
    var useCDN: Bool { get }
    
#if os(iOS)
    /// 是否显示loadView, Default is false
    var showLoadView: Bool { get }
    
    /// 显示加载框的动画类型, 若不设置则使用WBAlConfig内的配置
    var showLoadAnimationType: AnimationType? { get }
    
    /// 显示加载框文字的位置, 若不设置则使用WBAlConfig内的配置
    var showLoadTextPosition: TextLabelPosition? { get }
    
    /// 显示加载框文字的颜色, 若不设置则使用WBAlConfig内的配置
    var showLoadTextColor: UIColor? { get }
    
    /// 显示加载框文字的字体, 若不设置则使用WBAlConfig内的配置
    var showLoadTextFont: UIFont? { get }
    
    /// 显示加载框的文字, 若不设置则使用WBAlConfig内的配置
    var showLoadText: String? { get }
#endif
    
// MARK: - Response Properties
    /// 响应状态码
    var statusCode: Int { get }
}

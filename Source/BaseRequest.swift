//
//  BaseRequest.swift
//  WBAlamofire
//
//  Created by zwb on 2017/12/27.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation
import Alamofire
#if os(iOS)
    import UIKit
#endif

// MARK:  - WBAlRequestProtocol

///=============================================================================
/// @name WBAlRequestProtocol
///=============================================================================

/// Request Protoclo
///  The WBAlRequestProtocol protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue.
public protocol WBAlRequestProtocol : class {
    
    ///  The request finish
    ///  Tell the delegate that the request has finished successfully.
    ///  网络请求结束触发
    ///
    ///  @param request The corresponding request.
    func requestFinish(_ request: WBAlBaseRequest) -> Void
    
    ///  The request failed
    ///  Tell the delegate that the request has failed.
    ///  网络请求失败触发
    ///
    ///  @param request The corresponding request.
    func requestFailed(_ request: WBAlBaseRequest) -> Void
}

extension WBAlRequestProtocol {
    public func requestFinish(_ request: WBAlBaseRequest) -> Void { }
    
    public func requestFailed(_ request: WBAlBaseRequest) -> Void { }
}

// MARK:  - WBAlRequestAccessoryProtocol

///=============================================================================
/// @name WBAlRequestAccessoryProtocol
///=============================================================================

///  AlRequest Protocol
///  The WBAlRequestAccessoryProtocol protocol defines several optional methods that can be
///  used to track the status of a request. Objects that conforms this protocol
///  ("accessories") can perform additional configurations accordingly. All the
///  accessory methods will be called on the main queue.
public protocol WBAlRequestAccessoryProtocol {
    
    ///  the request will to begin
    ///  Inform the accessory that the request is about to start.
    /// 网络请求即将开始
    ///
    ///  @param request The corresponding request. WBAlRequest, WBAlChainRequest, WBAlBatchRequest
    func requestWillStart(_ request: Any) -> Void
    
    ///  the request will to end
    ///  Inform the accessory that the request is about to stop. This method is called
    ///  before executing `requestFinished` and `successCompletionBlock`.
    /// 网络请求即将结束
    ///
    ///  @param request The corresponding request. WBAlRequest, WBAlChainRequest, WBAlBatchRequest
    func requestWillStop(_ request: Any) -> Void
    
    ///  the request has come to an end
    ///  Inform the accessory that the request has already stoped. This method is called
    ///  after executing `requestFinished` and `successCompletionBlock`.
    /// 网络请求已经结束
    ///
    ///  @param request The corresponding request. WBAlRequest, WBAlChainRequest, WBAlBatchRequest
    func requestDidStop(_ request: Any) -> Void
}

// MARK:  - BaseRequest

///=============================================================================
/// @name BaseRequest
///=============================================================================

///  Base protocol
///  BaseRequest is the abstract class of network request. It provides many options
///  for constructing request. It's the base class of `WBAlRequest`.
public protocol BaseRequest {
    /// type define multi data.
    typealias WBAlMultipartFormData = MultipartFormData

    /// 上传数据时的closure
    /// A closure for upload data
    typealias WBAlMutableDataClosure = (_ data: WBAlMultipartFormData) -> Void
    
    /// 网络请求完成的closure
    /// A closure for request finish
    typealias WBAlRequestCompleteClosure = (_ request: WBAlBaseRequest) -> Void
    
    /// A dictionary of headers to apply to a `URLRequest`.
    typealias WBAlHTTPHeaders = [String: String]
    
///=============================================================================
/// @name Request Information
///=============================================================================
    
// MARK:  - SubClass Override
    
///=============================================================================
/// @name Subclass Override
///=============================================================================
    
    ///  需要更改baseURL时调用
    ///  The baseURL of request. This should only contain the host part of URL, e.g., http://www.example.com.
    ///  See also `requestURL`
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var baseURL: String { get }
    
    ///  每一个model请求的url
    ///  The URL path of request. This should only contain the path part of URL, e.g., /v1/user. See alse `baseURL`.
    ///
    ///  @discussion This will be concated with `baseURL` using [NSURL URLWithString:relativeToURL].
    ///  Because of this, it is recommended that the usage should stick to rules stated above.
    ///  Otherwise the result URL may not be correctly formed. See also `URLString:relativeToURL`
    ///  for more information.
    ///
    ///  Additionaly, if `requestURL` itself is a valid URL, it will be used as the result URL and
    ///  `baseURL` will be ignored.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var requestURL: String { get }
    
    ///  需要使用cdnURL时调用
    ///  Optional CDN URL for request.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var cdnURL: String { get }
    
    ///  请求的method
    ///  HTTP request method.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var requestMethod: WBAlHTTPMethod { get }
    
    ///  需要添加的请求头
    ///  Additional HTTP request header field.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var requestHeaders: WBAlHTTPHeaders? { get }
    
    ///  需要添加的请求参数
    ///  Additional request argument.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var requestParams: [String: Any]? { get }
    
    ///  请求时param编码
    ///  Request serializer type.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var paramEncoding: WBAlParameterEncoding { get }
    
    ///  请求返回的数据类型
    ///  Response serializer type. See also `responseObject`.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var responseType: WBAlResponseType { get }
    
    ///  请求的优先权
    ///  The priority of the request. Effective only on iOS 8+. Default is `WBALRequestPriority.default`.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var priority: WBAlRequestPriority? { get }
    
    // 上传文件时以下面三种任选一种作为上传数据依据
    ///  上传文件时上传的数据
    ///  This can be use to construct HTTP body when needed in POST request. Default is nil.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var requestDataClosure: WBAlMutableDataClosure? { get }
    
    ///  上传文件时文件的url
    ///  This can be use to construct HTTP body when needed in POST request. Default is nil.
    ///  If you want to upload a local file, you can use a local URL to upload this file.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var uploadFile: URL? { get }
    
    ///  上传文件时文件的data
    ///  This can be use to construct HTTP body when needed in POST request. Default is nil.
    ///  If you want to upload local data, you can use a local data to upload this data.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var uploadData: Data? { get }
    
    ///  下载文件保存的名字，默认存放在 .../Library/Caches/{WBAlConfig.shared.downFileName}/...下
    ///  This value is used to perform resumable download request. Default is empty string.
    ///  And the file save in .../Library/Caches/{WBAlConfig.shared.downFileName}.
    ///
    ///  @discussion NSURLSessionDownloadTask is used when this value is not nil.
    ///   The exist file at the path will be removed before the request starts. If request succeed, file will
    ///   be saved to this path automatically, otherwise the response will be saved to `responseData`
    ///   and `responseString`. For this to work, server must support `Range` and response with
    ///   proper `Last-Modified` and/or `Etag`. See `NSURLSessionDownloadTask` for more detail.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var resumableDownloadPath: String { get }
    
    ///  https时使用的证书的用户名以及密码, first is user, last is password.
    ///  Username and password used for HTTP authorization. Should be formed as @[@"Username", @"Password"].
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var requestAuthHeaders: [String]? { get }
    
    ///  是否使用cdn
    ///  Should use CDN when sending request.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var useCDN: Bool { get }

// MARK: - iOS LoadView
    
///=============================================================================
/// @name iOS LoadView
///=============================================================================
    
#if os(iOS)
    ///  是否显示loadView, Default is false
    ///  Whether show the loadView. if you want use it, must be true.
    ///  When it has used, will show a "Loading" HUD plug-in in the top ViewController's view.
    ///  Default is false.
    @available(iOS 8.0, *)
    var showLoadView: Bool { get }
    
    /// 显示加载框的动画类型, 若不设置则使用WBAlConfig内的配置
    /// According to the loading frame of animation types, if do not use the WBAlConfig
    /// within the configuration Settings
    @available(iOS 8.0, *)
    var showLoadAnimationType: AnimationType? { get }
    
    /// 显示加载框文字的位置, 若不设置则使用WBAlConfig内的配置
    /// Shows the location of the loading text box, if do not use the WBAlConfig
    /// within the configuration Settings
    @available(iOS 8.0, *)
    var showLoadTextPosition: TextLabelPosition? { get }
    
    /// 显示加载框文字的颜色, 若不设置则使用WBAlConfig内的配置
    /// The text box display color, if not use the WBAlConfig
    /// within the configuration Settings
    @available(iOS 8.0, *)
    var showLoadTextColor: UIColor? { get }
    
    /// 显示加载框文字的字体, 若不设置则使用WBAlConfig内的配置
    /// The box display text font, if do not use the WBAlConfig
    /// within the configuration Settings
    @available(iOS 8.0, *)
    var showLoadTextFont: UIFont? { get }
    
    /// 显示加载框的文字, 若不设置则使用WBAlConfig内的配置
    /// The text display loaded box, if don't use the WBAlConfig
    /// within the configuration Settings
    @available(iOS 8.0, *)
    var showLoadText: String? { get }
#endif
    
///=============================================================================
/// @name  Response Information
///=============================================================================
    
// MARK: - Response Properties
    
    ///  响应状态码
    ///  The response status code.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    var statusCode: Int { get }
}

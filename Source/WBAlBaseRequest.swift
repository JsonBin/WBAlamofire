//
//  WBAlBaseRequest.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/31.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation
import Alamofire
#if os(iOS)
    import UIKit
#endif

/// WBAlBaseRequest是实现BaseRequest的类，是完成基础的默认参数的设置，
/// 在这里面实现所有的基本参数的重写

///  WBAlBaseRequest is to realize the BaseRequest class, is the foundation of complete the
///  default parameter Settings, in which all the basic parameters can be rewritten. It's the
///  base class of `WBAlRequest`.
open class WBAlBaseRequest : BaseRequest {
  
// MARK: - Request Information
    
///=============================================================================
/// @name Request Information
///=============================================================================
    
    open var baseURL: String { return "" }
    
    open var requestURL: String { return "" }
    
    open var cdnURL: String { return "" }
    
    open var requestMethod: WBAlHTTPMethod { return .get }
    
    open var requestHeaders: WBAlHTTPHeaders? { return nil }
    
    open var requestParams: [String: Any]? { return nil }
    
    open var paramEncoding: WBAlParameterEncoding { return .json(encode: .default) }
    
    open var responseType: WBAlResponseType { return .json }
    
    open var priority: WBAlRequestPriority? { return nil }
    
    open var requestDataClosure: BaseRequest.WBAlMutableDataClosure? { return nil }
    
    open var uploadFile: URL? { return nil }

    open var uploadData: Data? { return nil }
    
    open var resumableDownloadPath: String { return "" }
    
    open var requestAuthHeaders: [String]? { return nil }

    open var useCDN: Bool { return false }
 
// MARK: - SubClass Override
    
///=============================================================================
/// @name Subclass Override
///=============================================================================
    
    /// 过滤请求params的方法, 可覆写. 默认不过滤
    /// Override this method to filter requests with certain arguments when caching.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    open func cacheFileNameFilterForRequestParams(_ params: [String: Any]) -> [String: Any] { return params }
    
    /// 请求完成成功响应方法 <** 在回到主线程之前的子线程响应，如果是加载的缓存，则一定是在主线程之中响应
    /// Called on background thread after request succeded but before switching to main thread. Note if
    /// cache is loaded, this method WILL be called on the main thread, just like `requestCompleteFilter`.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    open func requestCompletePreprocessor() -> Void {}
    
    /// 请求完成成功响应方法 <** 在主线程响应
    /// Called on the main thread after request succeeded.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    open func requestCompleteFilter() -> Void {}
    
    /// 请求失败完成响应方法 <** 在回到主线程之前的子线程中响应,可参考 `requestCompletePreprocessor`
    /// Called on background thread after request succeded but before switching to main thread. See also
    /// `requestCompletePreprocessor`.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    open func requestFailedPreprocessor() -> Void {}
    
    /// 请求失败完成响应方法 <** 在主线程响应
    /// Called on the main thread when request failed.
    @available(iOS 8.0, watchOS 2.0, tvOS 9.0, OSX 10.10, *)
    open func requestFailedFilter() -> Void {}

// MARK: - iOS LoadView
    
///=============================================================================
/// @name iOS LoadView
///=============================================================================
    
#if os(iOS)
    open var showLoadView: Bool { return false }
    
    open var showLoadAnimationType: AnimationType? { return nil }
    
    open var showLoadTextPosition: TextLabelPosition? { return nil }
    
    open var showLoadTextColor: UIColor? { return nil }
    
    open var showLoadTextFont: UIFont? { return nil }

    open var showLoadText: String? { return nil }
#endif
    
// MARK: - Public Properties
    
    /// use to request identify, Default 0
    /// Tag can be used to identify request. Default value is 0.
    open var tag: Int = 0
    
    /// 代理委托
    /// The delegate object of the request. If you choose block style callback you can ignore this.
    /// Default is nil.
    open weak var delegate: WBAlRequestProtocol?
    
    /// 网络请求的协议组
    /// This can be used to add several accossories object. Note if you use `add(_ requestAccessory:)` to add acceesory
    /// this array will be automatically created. Default is nil.
    open var requestAccessories: [WBAlRequestAccessoryProtocol]?
    
    /// 下载文件或上传文件的进度
    /// You can use this block to track the download progress. See also `resumableDownloadPath`.
    @available(*, deprecated: 1.2.1, message: "Use `progressHandler` instead.")
    open var downloadProgress: Request.ProgressHandler?

    /// 下载文件或上传文件的进度
    /// You can use this block to track the download progress. See also `resumableDownloadPath`.
    open var progressHandler: Request.ProgressHandler?
    
    /// 完成成功的回调
    /// The success callback. Note if this value is not nil and `requestFinished` delegate method is
    /// also implemented, both will be executed but delegate method is first called. This block
    /// will be called on the main queue.
    open var successCompleteClosure: BaseRequest.WBAlRequestCompleteClosure?
    
    /// 完成失败的回调
    /// The failure callback. Note if this value is not nil and `requestFailed` delegate method is
    /// also implemented, both will be executed but delegate method is first called. This block
    /// will be called on the main queue.
    open var failureCompleteClosure: BaseRequest.WBAlRequestCompleteClosure?
    
    /// 是否为需求请求成功状态码的范围内
    /// This validator will be used to test if `statusCodeValidator` is valid.
    open var statusCodeValidator: Bool {
        if WBAlConfig.shared.statusCode.contains(self.statusCode) {
            return true
        }
        return false
    }
    
// MARK: - Response Properties
    
///=============================================================================
/// @name  Response Information
///=============================================================================
    
    open var statusCode: Int { return request?.response?.statusCode ?? 500 }
    
    /// 请求状态
    /// Return cancelled state of request task.
    open var state : URLSessionTask.State? { return request?.task?.state }
    
    /// 请求获取的数据
    /// The raw data representation of response. Note this value may be nil if request failed.
    open var responseData: Data?
    
    /// 请求获取的string(返回类型为Data和String<objc返回为data时也生效>生效)
    /// The string representation of response. Note this value may be nil if request failed.
    open var responseString: String?
    
    /// 默认返回的数据结果
    /// This serialized response object. The actual type of this object is determined by
    /// `WBAlResponseType.default` or `WBAlResponseType.data`. Note this value
    /// can be nil if request failed.
    ///
    /// @discussion If `resumableDownloadPath` and DownloadTask is using, this value will
    /// be the path to which file is successfully saved (NSURL), or nil if request failed.
    open var responseObj: Any?
    
    /// 返回为json时请求的结果
    /// If you use `WBAlResponseType.json`, this is a convenience (and sematic) getter
    /// for the response Json. Otherwise this value is nil.
    open var responseJson: [String: Any]?
    
    /// 返回为plist时请求的结果
    /// If you use `WBAlResponseType.plist`, this is a convenience (and sematic) getter
    /// for the response Plist. Otherwise this value is nil.
    open var responsePlist: Any?
    
    /// 这是下载专用的url，仅当有下载时才生效. Default nil.
    /// If you use `resumableDownloadPath`, this is a convenience (and sematic) getter
    /// for the response result. Otherwise this value is nil.
    open var downloadURL: URL?
    
    /// 请求失败error
    /// This error can be either serialization error or network error. If nothing wrong happens
    /// this value will be nil.
    open var error: Error?
    
    /// The current request.
    open var request: Request?
    
// MARK: - Init
    
    public init() {}
    
// MARK: - Request Action
    
///=============================================================================
/// @name Request Action
///=============================================================================
    
    /// Append self to request queue and start the request.
    open func start() -> Void {
        self.totalAccessoriesWillStart()
        WBAlamofire.shared.add(self)
    }
    
    /// Remove self from request queue and cancel the request.
    open func stop() -> Void {
        self.totalAccessoriesWillStop()
        self.delegate = nil
        WBAlamofire.shared.cancel(self)
        self.totalAccessoriesDidStop()
    }
    
    /// Convenience method to start the request with block callbacks.
    open func start(_ success: BaseRequest.WBAlRequestCompleteClosure?, failure failureClosure: BaseRequest.WBAlRequestCompleteClosure? = nil) {
        self.set(success, failure: failureClosure)
        
        self.start()
    }
    
    /// Set completion callbacks
    open func set(_ success: BaseRequest.WBAlRequestCompleteClosure?, failure failureClosure: BaseRequest.WBAlRequestCompleteClosure?) {
        self.successCompleteClosure = success
        self.failureCompleteClosure = failureClosure
    }
    
    /// Convenience method to add request accessory. See also `requestAccessories`.
    open func add(_ requestAccessory: WBAlRequestAccessoryProtocol) {
        if requestAccessories == nil {
            requestAccessories = [WBAlRequestAccessoryProtocol]()
        }
        requestAccessories?.append(requestAccessory)
    }
    
    /// Nil out both success and failure callback blocks.
    open func clearCompleteClosure() {
        // set nil out to break the retain cycle.
        self.successCompleteClosure = nil
        self.failureCompleteClosure = nil
    }
    
// MARK: - Custom Request
    
    /// Use this to build custom request. If this method return non-nil value, `requestURL`,
    /// `requestParams`, , `requestMethod` and `paramEncoding` will all be ignored.
    open var buildCustomRequest: URLRequest? { return nil }
}

// MARK: - WBAlRequestAccessoryProtocol
extension WBAlBaseRequest {
    
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

//
//  WBAlConfig.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/24.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation
import Alamofire
#if os(iOS)
    import UIKit
#endif

///  WBAlURLFilterProtocol can be used to append common parameters to requests before sending them.
public protocol WBAlURLFilterProtocol {
    /// Preprocess request URL before actually sending them.
    ///
    /// - Parameters:
    ///   - originURL: request's origin URL, which is returned by `requestUrl`
    ///   - request: request itself
    /// - Returns: A new url which will be used as a new `requestUrl`
    func filterURL(_ originURL: String, baseRequest request: WBAlBaseRequest) -> String
}

///  WBAlCacheDirPathFilterProtocol can be used to append common path components when caching response results
public protocol WBAlCacheDirPathFilterProtocol {
    /// Preprocess cache path before actually saving them.
    ///
    /// - Parameters:
    ///   - originPath: original base cache path, which is generated in `WBAlBaseRequest` class.
    ///   - request: request itself
    /// - Returns: A new path which will be used as base path when caching.
    func filterCacheDirPath(_ originPath: String, baseRequest request: WBAlBaseRequest) -> String
}

///  WBAlConfig stored global network-related configurations, which will be used in `WBAlamofire`
///  to form and filter requests, as well as caching response.
public final class WBAlConfig {
    
    ///  Return a shared config object.
    public static let shared = WBAlConfig()
    
// MARK: - Public Properties
    
///=============================================================================
/// @name Public Properties
///=============================================================================
    
    /// 配置项目的baseURL
    ///  Request base URL, such as "http://www.baidu.com". Default is empty string.
    public var baseURL: String
    
    /// 配置项目的cdnURL
    ///  Request CDN URL. Default is empty string.
    public var cdnURL: String
    
    /// 网络请求超时时间, Default 30s
    /// Request time out interval. Default is 30s.
    public var requestTimeoutInterval: TimeInterval
    
    /// 设置响应状态码的范围, 默认为(200-300)
    /// Request vaildator code. Default is 200~300.
    public var statusCode: [Int]
    
    /// 设置返回接受类型
    /// Set to return to accept type
    public var acceptType: [String]
    
    /// 是否能通过蜂窝网络访问数据, Default true
    /// Whether allow cellular. Default is true.
    public var allowsCellularAccess: Bool
    
    /// 是否开启日志打印，默认false
    ///  Whether to log debug info. Default is NO.
    public var debugLogEnable: Bool
    
    /// 是否开启监听网络，默认true
    /// Whether public network monitoring. Default is true.
    public var listenNetWork: Bool
    
    /// url protocol协议组
    ///  URL filters. See also `WBAlURLFilterProtocol`.
    public var urlFilters: [WBAlURLFilterProtocol]
    
    /// cache dirpath protocol 协议组
    ///  Cache path filters. See also `WBAlCacheDirPathFilterProtocol`.
    public var cacheDirPathFilters: [WBAlCacheDirPathFilterProtocol]
    
    ///  serverPolicy will be used to Alamofire. Default nil.
    ///  Security policy will be used by Alamofire. See also `ServerTrustPolicyManager`.
    public var serverPolicy: ServerTrustPolicyManager?
    
    ///  SessionConfiguration will be used to Alamofire.
    public var sessionConfiguration: URLSessionConfiguration
    
    ///  缓存请求文件的文件夹名, 位于`/Library/Caches/{cacheFileName}`
    /// Save to disk file name.
    public var cacheFileName = "wbalamofire.request.cache.default"
    
    /// 下载文件时保存的文件名, 位于`/Library/Caches/{downFileName}`下
    /// Download file name
    public var downFileName = "wbalamofire.download.default"
   
// MARK: - Only iOS LoadView
    
///=============================================================================
/// @name Only iOS LoadView
///=============================================================================
    
#if os(iOS)
    /// 加载框的动画类型，默认为native
    /// The load view animationType. Default is native.
    public var loadViewAnimationType = AnimationType.native
    
    /// 加载框的文字位置，默认为bottom
    /// The load view text position. Default is bottom.
    public var loadViewTextPosition = TextLabelPosition.bottom
    
    /// 加载框的文字颜色，默认为白色
    /// The load view textColor. Default is white.
    public var loadViewTextColor = UIColor.white
    
    /// 加载框的文字大小，默认为15.
    /// The load view text font. Default is 15.
    public var loadViewTextFont = UIFont.systemFont(ofSize: 15)
    
    /// 加载框显示的文字，默认为Loading
    /// The load view text. Default is 'Loading'.
    public var loadViewText = "Loading"
#endif
    
// MARK: - Cycle Life
    
///=============================================================================
/// @name Cycle Life
///=============================================================================
    
    public init() {
        self.baseURL = ""
        self.cdnURL = ""
        self.requestTimeoutInterval = 30
        self.statusCode = Array(200..<300)
        self.acceptType = ["application/json", "text/json", "text/javascript", "text/html", "text/plain", "image/jpeg"]
        self.allowsCellularAccess = true
        self.debugLogEnable = false
        self.listenNetWork = true
        self.serverPolicy = nil
        self.urlFilters = [WBAlURLFilterProtocol]()
        self.cacheDirPathFilters = [WBAlCacheDirPathFilterProtocol]()
        self.sessionConfiguration = .default
    }
    
    public init(baseURL: String, cdnURL: String, requestTimeoutInterval: TimeInterval, statusCode: [Int], acceptType: [String], allowsCellularAccess: Bool, debugLogEnable: Bool, listenNetWork: Bool, serverPolicy: ServerTrustPolicyManager?, urlFilters: [WBAlURLFilterProtocol], cacheDirPathFilters: [WBAlCacheDirPathFilterProtocol], sessionConfiguration: URLSessionConfiguration) {
        self.baseURL = baseURL
        self.cdnURL = cdnURL
        self.requestTimeoutInterval = requestTimeoutInterval
        self.statusCode = statusCode
        self.acceptType = acceptType
        self.allowsCellularAccess = allowsCellularAccess
        self.debugLogEnable = debugLogEnable
        self.listenNetWork = listenNetWork
        self.serverPolicy = serverPolicy
        self.urlFilters = urlFilters
        self.cacheDirPathFilters = cacheDirPathFilters
        self.sessionConfiguration = sessionConfiguration
    }
    
// MARK: - Public
    
///=============================================================================
/// @name Public
///=============================================================================
    
    ///  Add a new URL filter.
    public func add(_ urlFilter: WBAlURLFilterProtocol) {
        urlFilters.append(urlFilter)
    }
    
    ///  Add a new cache path filter
    public func add(_ cacheFilter: WBAlCacheDirPathFilterProtocol) {
        cacheDirPathFilters.append(cacheFilter)
    }
    
    ///  Remove all URL filters.
    public func cleanURLFilters() -> Void {
        urlFilters.removeAll()
    }
    
    ///  Clear all cache path filters.
    public func cleanCacheFilters() -> Void {
        cacheDirPathFilters.removeAll()
    }
}

// MARK: - Description

///=============================================================================
/// @name Description
///=============================================================================

extension WBAlConfig : CustomStringConvertible {
    public var description: String {
        return String(format: "<%@: %p>{ bseURL: %@ } { cdnURL: %@ }", #file, #function, baseURL, cdnURL)
    }
}

// MARK: - Debug Description

///=============================================================================
/// @name Debug Description
///=============================================================================

extension WBAlConfig : CustomDebugStringConvertible {
    public var debugDescription: String {
        return String(format: "<%@: %p>{ bseURL: %@ } { cdnURL: %@ }", #file, #function, baseURL, cdnURL)
    }
}

// MARK: - GCD

///=============================================================================
/// @name GCD
///=============================================================================

extension DispatchQueue {
    public static var wbCurrent: DispatchQueue {
        let name = String(format: "com.wbalamofire.request.%08x%08x", arc4random(),arc4random())
        return DispatchQueue(label: name, attributes: .concurrent)
    }
}

// MARK: - Print Logs

///=============================================================================
/// @name Print Logs
///=============================================================================

public func WBALog<T>(_ message: T, file File: NSString = #file, method Method: String = #function, line Line: Int = #line) -> Void {
    if WBAlConfig.shared.debugLogEnable {
        #if DEBUG
            print("<\(File.lastPathComponent)>{Line:\(Line)}-[\(Method)]:\(message)")
        #endif
    }
}

//
//  WBAlConfig.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/24.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation

/// 过滤/重构URL的协议
public protocol WBAlURLFilterProtocol {
    func filterURL(_ originURL: String, baseRequest request: WBAlBaseRequest) -> String
}

/// 过滤/重编缓存路径的协议
public protocol WBAlCacheDirPathFilterProtocol {
    func filterCacheDirPath(_ originPath: String, baseRequest request: WBAlBaseRequest) -> String
}

/// 网络请求配置类
open class WBAlConfig {
    
    /// 实例化，项目唯一
    open static let shared = WBAlConfig()
    
    /// 配置项目的baseURL
    open var baseURL: String
    
    /// 配置项目的cdnURL
    open var cdnURL: String
    
    /// 网络请求超时时间, Default 30s
    open var requestTimeoutInterval: TimeInterval
    
    /// 设置响应状态码的范围, 默认为(200-300)
    open var statusCode = 0..<1
    
    /// 是否能通过蜂窝网络访问数据, Default true
    open var allowsCellularAccess: Bool
    
    /// 是否开启日志打印，默认false
    open var debugLogEnable: Bool
    
    /// 是否开启监听网络，默认true
    open var listenNetWork: Bool
    
    /// url protocol协议组
    open var urlFilters: [WBAlURLFilterProtocol]
    
    /// cache dirpath protocol 协议组
    open var cacheDirPathFilters: [WBAlCacheDirPathFilterProtocol]
    
    /// serverPolicy will be used to Alamofire. Default nil.
    open var serverPolicy: ServerTrustPolicyManager!
    
    /// SessionConfiguration will be used to Alamofire.
    open var sessionConfiguration: URLSessionConfiguration
    
    /// Save to disk file name. 缓存请求文件的文件夹名
    open var cacheSpace = "WBAlamofire.requestCache.default"
    
// MARK: - Init
    public init() {
        self.baseURL = ""
        self.cdnURL = ""
        self.requestTimeoutInterval = 30
        self.statusCode = 200..<300
        self.allowsCellularAccess = true
        self.debugLogEnable = false
        self.listenNetWork = true
        self.serverPolicy = nil
        self.urlFilters = [WBAlURLFilterProtocol]()
        self.cacheDirPathFilters = [WBAlCacheDirPathFilterProtocol]()
        self.sessionConfiguration = .default
    }
    
    public init(baseURL:String = "", cdnURL: String = "", requestTimeoutInterval:TimeInterval = 30, allowsCellularAccess:Bool = true, debugLogEnable:Bool = false, listenNetWork:Bool = true, serverPolicy:ServerTrustPolicyManager? = nil , urlFilters: [WBAlURLFilterProtocol] = [], cacheDirPathFilters: [WBAlCacheDirPathFilterProtocol] = [], sessionConfiguration:URLSessionConfiguration = .default) {
        self.baseURL = baseURL
        self.cdnURL = cdnURL
        self.requestTimeoutInterval = requestTimeoutInterval
        self.statusCode = 200..<300
        self.allowsCellularAccess = allowsCellularAccess
        self.debugLogEnable = debugLogEnable
        self.listenNetWork = listenNetWork
        self.serverPolicy = serverPolicy
        self.urlFilters = urlFilters
        self.cacheDirPathFilters = cacheDirPathFilters
        self.sessionConfiguration = sessionConfiguration
    }
    
// MARK: - Public
    open func add(_ urlFilter: WBAlURLFilterProtocol) {
        urlFilters.append(urlFilter)
    }
    
    open func add(_ cacheFilter: WBAlCacheDirPathFilterProtocol) {
        cacheDirPathFilters.append(cacheFilter)
    }
    
    open func cleanURLFilters() -> Void {
        urlFilters.removeAll()
    }
    
    open func cleanCacheFilters() -> Void {
        cacheDirPathFilters.removeAll()
    }
}

// MARK: - Description
extension WBAlConfig : CustomStringConvertible {
    open var description: String {
        return String(format: "<%@: %p>{ bseURL: %@ } { cdnURL: %@ }", #file, #function, baseURL, cdnURL)
    }
}

// MARK: - Debug Description
extension WBAlConfig : CustomDebugStringConvertible {
    open var debugDescription: String {
        return String(format: "<%@: %p>{ bseURL: %@ } { cdnURL: %@ }", #file, #function, baseURL, cdnURL)
    }
}

// MARK: - GCD
extension DispatchQueue {
    public class var WBALAsyncDispatchQueue: DispatchQueue {
        let name = String(format: "com.wbAlamofire.request.%08x%08x", arc4random(),arc4random())
        return DispatchQueue(label: name)
    }
}

// 打印日志
public func WBALog<T>(_ message:T, file File:NSString = #file, method Method:String = #function, line Line:Int = #line) -> Void {
    if WBAlConfig.shared.debugLogEnable {
        #if DEBUG
            print("<\(File.lastPathComponent)>{Line:\(Line)}-[\(Method)]:\(message)")
        #endif
    }
}

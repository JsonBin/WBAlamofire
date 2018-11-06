//
//  WBAlRequest.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/24.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation

/// While reading web cache data error code
/// 读取网络缓存数据时错误码
///
/// - expired: expired
/// - versionMismatch: Version mismatch
/// - sensitiveDataMismatch: sensitive Data mismatch
/// - appVersionMismatch: app versions mismatch
/// - invalidCacheTime: Cache time error
/// - invalidMetadata: meta Data error
/// - invalidCacheData: Cache the data error
public enum WBAlRequestCacheDomain: Int {
    case expired = -1
    case versionMismatch = -2
    case sensitiveDataMismatch = -3
    case appVersionMismatch = -4
    case invalidCacheTime = -5
    case invalidMetadata = -6
    case invalidCacheData = -7
}

/// 网络请求的子类
/// 缓存的网络数据默认放在.../Library/{WBAlConfig.shared.cacheFileName}/..目录下
///  WBAlRequest is the base class you should inherit to create your own request class.
///  Based on WBAlBaseRequest, WBAlRequest adds local caching feature. Note download
///  request will not be cached whatsoever, because download request may involve complicated
///  cache control policy controlled by `Cache-Control`, `Last-Modified`, etc.
///  And the cache data will save in .../Library/{WBAlConfig.shared.cacheFileName}/..
open class WBAlRequest : WBAlBaseRequest {
    
    /// 是否不使用缓存作为网络请求返回数据，默认false
    ///  Whether to use cache as response or not.
    ///  Default is NO, which means caching will take effect with specific arguments.
    ///  Note that `cacheInSeconds` default is 2m. As a result cache data is not actually
    ///  used as response unless you return a positive value in `cacheInSeconds`.
    ///
    ///  Also note that this option does not affect storing the response, which means
    ///  response will always be saved
    ///  even `ignoreCache` is YES.
    open var ignoreCache: Bool = false
    
    /// 返回是否是从缓存读取的数据
    ///  Whether data is from local cache.
    open var isDataFromCache: Bool { return _dataFromCache }
    
// MARK: - SubClass Override
    
///=============================================================================
/// @name SubClass Override
///=============================================================================
    
    /// 多长时间范围内不进行网络请求，使用缓存作为请求的返回数据.默认2m
    ///  The max time duration that cache can stay in disk until it's considered expired.
    ///  Default is 2m, which means response will actually saved as cache.
    open var cacheInSeconds: TimeInterval { return 2 * 60 }
    
    /// 以版本号来缓存数据
    ///  Version can be used to identify and invalidate local cache. Default is 0.
    open var cacheVersion: Int { return 0 }
    
    /// sensitive data (可以根据两次不同的数据自动更新缓存)
    ///  This can be used as additional identifier that tells the cache needs updating.
    ///
    ///  @discussion The `description` string of this object will be used as an identifier to verify whether cache
    ///   is invalid. Using `NSArray` or `NSDictionary` as return value type is recommended. However,
    ///   If you intend to use your custom class type, make sure that `description` is correctly implemented.
    open var cacheSensitiveData: Data? { return nil }
    
    /// 是否自动异步缓存数据, Default true.
    ///  Whether cache is asynchronously written to storage. Default is YES.
    open var writeCacheAsynchronously: Bool { return true }
   
// MARK: - Private Properties
    
///=============================================================================
/// @name Cache Response
///=============================================================================
    
    private var _cacheData: Data?
    private var _cacheString: String?
    private var _cacheJson: [String: Any]?
    private var _cachePlist: Any?
    
///=============================================================================
/// @name Other Infomations
///=============================================================================
    
    private var _dataFromCache:Bool = false
    private var _cacheMetadata: WBAlMetadata?
    private let WBAlRequestCahceErrorDomain = "com.wbalamofire.request.cache"
    
// MARK: - Override WBAlBaseRequest Response
    
///=============================================================================
/// @name Override WBAlBaseRequest Response
///=============================================================================
    
    open override var responseData: Data? {
        set{ super.responseData = newValue }
        get{
            if let data = _cacheData {
                return data
            }
            return super.responseData
        }
    }
    
    open override var responseString: String? {
        set { super.responseString = newValue }
        get {
            if let string = _cacheString {
                return string
            }
            return super.responseString
        }
    }
    
    open override var responseObj: Any? {
        set { super.responseObj = newValue }
        get {
            if let data = _cacheData {
                return data
            }
            return super.responseObj
        }
    }
    
    open override var responseJson: [String: Any]? {
        set { super.responseJson = newValue }
        get {
            if let json = _cacheJson {
                return json
            }
            return super.responseJson
        }
    }
    
    open override var responsePlist: Any? {
        set { super.responsePlist = newValue }
        get {
            if let plist = _cachePlist {
                return plist
            }
            return super.responsePlist
        }
    }
    
// MARK: - Request Action
    
///=============================================================================
/// @name Request Action
///=============================================================================
    
    open override func start() {
        if self.ignoreCache {
            startWithOutCache()
            return
        }
        
        // Have download requst, don't cache request
        if !self.resumableDownloadPath.isEmpty {
            startWithOutCache()
            return
        }
        
        var error:Error? = nil
        if !loadCacheWithError(&error) {
            // if load cache data, print error info.
            if let e = error { WBALog(e) }
            startWithOutCache()
            return
        }
        
        _dataFromCache = true
        
        DispatchQueue.main.async {
            self.requestCompletePreprocessor()
            self.requestCompleteFilter()
            
            self.delegate?.requestFinish(self)
            if let success = self.successCompleteClosure {
                success(self)
            }
            self.clearCompleteClosure()
        }
    }
    
    ///  Start request without reading local cache even if it exists. Use this to update local cache.
    open func startWithOutCache() -> Void {
        clearCacheVariables()
        super.start()
    }
    
// MARK: - Save Data
    
///=============================================================================
/// @name Save Data
///=============================================================================
    
    ///  Save response data (probably from another request) to this request's cache location
    open func saveResponseDataToCacheFile(_ data: Data?) {
        if self.cacheInSeconds > 0 && !self.isDataFromCache {
            if let data = data, data.count > 0 {
                // cache
                do {
                    try data.write(to: URL(fileURLWithPath: WBAlCache.shared.cacheFilePath(self)), options: .atomic)
                } catch let reason {
                    WBALog("Save cache failed, reason: \"\(reason.localizedDescription)\"")
                }
                let metadata = WBAlMetadata()
                metadata.version = self.cacheVersion
                metadata.sensitiveDataString = self.cacheSensitiveData?.description
                metadata.stringEncoding = WBAlUtils.stringEncodingFromRequest(self)
                metadata.createDate = Date()
                metadata.appVersionString = WBAlUtils.appVersion
                NSKeyedArchiver.archiveRootObject(metadata, toFile: WBAlCache.shared.cacheMetadataFilePath(self))
            }
        }
    }
    
// MARK:  - Request Delegate
    
///=============================================================================
/// @name Request Delegate
///=============================================================================
    
    open override func requestCompletePreprocessor() {
        super.requestCompletePreprocessor()
        
        // 下载文件不缓存
        if !self.resumableDownloadPath.isEmpty { return }
        
        if self.writeCacheAsynchronously {
            // 自动异步缓存
            DispatchQueue.wbCurrent.async {
                self.saveResponseDataToCacheFile(super.responseData)
            }
        }else{
            // 自动缓存
            saveResponseDataToCacheFile(super.responseData)
        }
    }
    
// MARK:  - Privates
    
///=============================================================================
/// @name Privates Func
///=============================================================================
    
    private func clearCacheVariables() -> Void {
        _cacheData = nil
        _cacheJson = nil
        _cacheString = nil
        _cachePlist = nil
        _cacheMetadata = nil
        _dataFromCache = false
    }
    
    ///  Manually load cache from storage.
    ///
    ///  @param error If an error occurred causing cache loading failed, an error object will be passed, otherwise NULL.
    ///
    ///  @return Whether cache is successfully loaded.
    private func loadCacheWithError(_ error: inout Error? ) -> Bool {
         // Make sure cache time in valid.
        if self.cacheInSeconds < 0 {
            if error != nil {
                error = NSError(domain: WBAlRequestCahceErrorDomain, code: WBAlRequestCacheDomain.invalidCacheTime.rawValue, userInfo: [NSLocalizedDescriptionKey:"Invalid cache time."])
            }
            return false
        }
        
        // try load metadata
        if !self.loadCacheMetadata {
            if error != nil {
                error = NSError(domain: WBAlRequestCahceErrorDomain, code: WBAlRequestCacheDomain.invalidMetadata.rawValue, userInfo: [NSLocalizedDescriptionKey:"Invalid metadata. may be cache not exists."])
            }
            return false
        }
        
        // Check if cache is still valid.
        if !self.validateCacheWithError(&error) {
            return false
        }
        
        // try load cache data
        if !self.loadCacheData {
            if error != nil {
                error = NSError(domain: WBAlRequestCahceErrorDomain, code: WBAlRequestCacheDomain.invalidCacheData.rawValue, userInfo: [NSLocalizedDescriptionKey:"Invalid cache data."])
            }
            return false
        }
        
        return true
    }
    
    private func validateCacheWithError(_ error: inout Error? ) -> Bool {
        // Date
        if let cacheDate = _cacheMetadata?.createDate {
            let duration = -cacheDate.timeIntervalSinceNow
            if duration < 0 || duration > self.cacheInSeconds {
                if error != nil {
                    error = NSError(domain: WBAlRequestCahceErrorDomain, code: WBAlRequestCacheDomain.expired.rawValue, userInfo: [NSLocalizedDescriptionKey:"Cache expired."])
                }
                return false
            }
        }
        
        // Version
        if let version = _cacheMetadata?.version {
            if version != self.cacheVersion {
                if error != nil {
                    error = NSError(domain: WBAlRequestCahceErrorDomain, code: WBAlRequestCacheDomain.versionMismatch.rawValue, userInfo: [NSLocalizedDescriptionKey:"Cache version misMatch."])
                }
                return false
            }
        }
        
        // SensitiveData
        let sensitiveString = _cacheMetadata?.sensitiveDataString
        let currentSensitiveString = self.cacheSensitiveData?.description
        if currentSensitiveString != nil || sensitiveString != nil {
            if currentSensitiveString?.count != sensitiveString?.count || currentSensitiveString != sensitiveString {
                if error != nil {
                    error = NSError(domain: WBAlRequestCahceErrorDomain, code: WBAlRequestCacheDomain.versionMismatch.rawValue, userInfo: [NSLocalizedDescriptionKey:"Cache sensitive data misMatch."])
                }
                return false
            }
        }
        
        // App Version
        let appVersion = _cacheMetadata?.appVersionString
        let currentAppVersion = WBAlUtils.appVersion
        if appVersion != nil || currentAppVersion != nil {
            if appVersion?.count != currentAppVersion?.count || appVersion != currentAppVersion {
                if error != nil {
                    error = NSError(domain: WBAlRequestCahceErrorDomain, code: WBAlRequestCacheDomain.appVersionMismatch.rawValue, userInfo: [NSLocalizedDescriptionKey:"App version misMatch."])
                }
                return false
            }
        }
        
        return true
    }
    
// MARK: - Cache
    
    /// Metadata
    private var loadCacheMetadata: Bool {
        let path = WBAlCache.shared.cacheMetadataFilePath(self)
        let manager = FileManager.default
        if manager.fileExists(atPath: path, isDirectory: nil) {
            
            if let meta = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? WBAlMetadata {
                _cacheMetadata = meta
                return true
            }
            WBALog("Load cache metadata failed.")
            return false
        }
        return false
    }
    
    /// Data
    private var loadCacheData: Bool {
        let path = WBAlCache.shared.cacheFilePath(self)
        let manager = FileManager.default
        
        if manager.fileExists(atPath: path, isDirectory: nil) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                _cacheData = data
                if let encoding = _cacheMetadata?.stringEncoding {
                    _cacheString = String(data: data, encoding: encoding)
                }
                switch self.responseType {
                case .default, .data, .string:
                    return true
                case .json:
                    _cacheJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                    return true
                case .plist:
                    _cachePlist = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil)
                    return true
                }
            } catch let reason {
                WBALog("Load cache Data is failed, reason: \"\(reason.localizedDescription)\"")
                return false
            }
        }
        return false
    }
}

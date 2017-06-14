//
//  WBAlRequest.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/24.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation

/// 读取网络缓存数据是错误码
///
/// - expired: 超时
/// - versionMismatch: 版本不匹配
/// - sensitiveDataMismatch: sensitive Data 不匹配
/// - appVersionMismatch: app版本不匹配
/// - invalidCacheTime: 缓存时间错误
/// - invalidMetadata: meta Data错误
/// - invalidCacheData: 缓存数据错误
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
/// 缓存的网络数据默认放在.../Library/WBAlamofire.requestCache.default/..目录下
open class WBAlRequest : WBAlBaseRequest{
    
    /// 是否不使用缓存作为网络请求返回数据，默认false
    open var ignoreCache: Bool = false
    
    /// 返回是否是从缓存读取的数据
    open var isDataFromCache: Bool { return _dataFromCache }
    
// MARK: - Cache Response
    private var _cacheData: Data?
    private var _cacheString: String?
    private var _cacheJson: [String: Any]?
    private var _cachePlist: Any?
    
// MARK: - Private Properties
    private var _dataFromCache:Bool = false
    private var _cacheMetadata: WBAlMetadata?
    private let WBAlRequestCahceErrorDomain = "com.wbAlamofire.request.cache"
    
// MARK: - Override SuperClass
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
    
// MARK:  - Start
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
    
    open func startWithOutCache() -> Void {
        clearCacheVariables()
        super.start()
    }
    
// MARK: - Save Data
    open func saveResponseDataToCacheFile(_ data:Data?) {
        if self.cacheInSeconds > 0 && !self.isDataFromCache {
            if let data = data, data.count > 0 {
                // cache
                do {
                    try data.write(to: URL(fileURLWithPath: cacheFilePath), options: .atomic)
                } catch let reason {
                    WBALog("Save cache failed, reason: \"\(reason.localizedDescription)\"")
                }
                let metadata = WBAlMetadata()
                metadata.version = self.cacheVersion
                metadata.sensitiveDataString = (self.cacheSensitiveData as AnyObject).description
                metadata.stringEncoding = WBAlUtils.stringEncodingFromRequest(self)
                metadata.createDate = Date()
                metadata.appVersionString = WBAlUtils.appVersion()
                NSKeyedArchiver.archiveRootObject(metadata, toFile: cacheMetadataFilePath)
            }
        }
    }
    
// MARK: - Request Delegate
    open override func requestCompletePreprocessor() {
        super.requestCompletePreprocessor()
        
        // 下载文件不缓存
        if !self.resumableDownloadPath.isEmpty { return }
        
        if self.writeCacheAsynchronously {
            // 自动异步缓存
            DispatchQueue.WBALAsyncDispatchQueue.async {
                self.saveResponseDataToCacheFile(super.responseData)
            }
        }else{
            // 自动缓存
            saveResponseDataToCacheFile(super.responseData)
        }
    }
    
// MARK:  - SubClass Override
    
    /// 多长时间范围内不进行网络请求，使用缓存作为请求的返回数据.默认2m
    open var cacheInSeconds: TimeInterval { return 2 * 60 }
    
    /// 以版本号来缓存数据
    open var cacheVersion: Int { return 0 }
    
    /// sensitive data (可以根据两次不同的数据自动更新缓存)
    open var cacheSensitiveData: Any? { return nil }
    
    /// 是否自动异步缓存数据, Default true.
    open var writeCacheAsynchronously: Bool { return true }
    
// MARK:  - Privates
    
    private func clearCacheVariables() -> Void {
        _cacheData = nil
        _cacheJson = nil
        _cacheString = nil
        _cachePlist = nil
        _cacheMetadata = nil
        _dataFromCache = false
    }
    
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
        let currentSensitiveString = (self.cacheSensitiveData as AnyObject).description
        if currentSensitiveString != nil || sensitiveString != nil {
            if currentSensitiveString?.characters.count != sensitiveString?.characters.count || currentSensitiveString != sensitiveString {
                if error != nil {
                    error = NSError(domain: WBAlRequestCahceErrorDomain, code: WBAlRequestCacheDomain.versionMismatch.rawValue, userInfo: [NSLocalizedDescriptionKey:"Cache sensitive data misMatch."])
                }
                return false
            }
        }
        
        // App Version
        let appVersion = _cacheMetadata?.appVersionString
        let currentAppVersion = WBAlUtils.appVersion()
        if appVersion != nil || currentAppVersion != nil {
            if appVersion?.characters.count != currentAppVersion?.characters.count || appVersion != currentAppVersion {
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
        let path = cacheMetadataFilePath
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
        let path = cacheFilePath
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
    
// MARK: - File && URL
    
    private var cacheFilePath: String {
        let cacheName = "/" + self.cacheFileName()
        let cachePath = self.cacheBasePath()
        return cachePath.appending(cacheName)
    }
    
    private var cacheMetadataFilePath: String {
        let metaName = "/" + self.cacheFileName() + ".metadata"
        let metaPath = self.cacheBasePath()
        return metaPath.appending(metaName)
    }
    
    private func cacheFileName() -> String {
        let requestURL = self.requestURL
        let baseURL = WBAlConfig.shared.baseURL
        var requestInfo = String(format: "Host:%@, Url:%@, Method:%@", baseURL, requestURL, self.requestMethod.rawValue)
        if let params = self.requestParams {
            let params = self.cacheFileNameFilterForRequestParams(params)
            requestInfo = requestInfo.appendingFormat(", Params:%@", params)
        }
        let cacheFileName = WBAlUtils.md5WithString(requestInfo)
        return cacheFileName
    }
    
    private func cacheBasePath() -> String {
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
        var cachePath = path.appending("/" + WBAlConfig.shared.cacheSpace)
        
        // Filter cache dirPath if needed
        let filters = WBAlConfig.shared.cacheDirPathFilters
        if !filters.isEmpty {
            for filter in filters {
                cachePath = filter.filterCacheDirPath(cachePath, baseRequest: self)
            }
        }
        
        let manager = FileManager.default
        var isDirectory:ObjCBool = true
        if !manager.fileExists(atPath: cachePath, isDirectory: &isDirectory) {
            isDirectory = false
            // create
            createBaseCachePath(cachePath)
        }else{
            if !isDirectory.boolValue {
                try? manager.removeItem(atPath: cachePath)
                createBaseCachePath(cachePath)
            }
        }
        
        return cachePath
    }
    
    private func createBaseCachePath(_ path:String) {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            WBAlUtils.addNotBackupAttribute(path)
        } catch let reason {
            WBALog("Create cache directory failed, reason = \"\(reason.localizedDescription)\"")
        }
    }
}

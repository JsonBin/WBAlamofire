//
//  WBAlCache.swift
//  WBAlamofire
//
//  Created by zwb on 2017/12/27.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation

/// WBAlCache is a cache handler class
public struct WBAlCache {
    
    public static let shared = WBAlCache()

    public typealias CacheSizeCompleteClosure = (_ size: Double) -> Void
    public typealias CacheSizeCleanClosure = (_ complete: Bool) -> Void
    
// MARK: - Cache and Download Files Size
    
///=============================================================================
/// @name Cache and Download Files Size
///=============================================================================
    
    /// 所有下载文件的大小.
    /// The download files size.
    ///
    /// - Parameter complete: calculate the download file size with closure
    public func downloadCacheSize(_ complete: @escaping CacheSizeCompleteClosure) {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/\(WBAlConfig.shared.downFileName)")
        guard let filePath = path else {
            complete(0)
            return
        }
        forderSize(with: filePath, complete: complete)
    }
    
    /// 所有缓存文件的大小.
    /// The cache files size.
    ///
    /// - Parameter complte: calculate the response cache file size with closure
    public func responseCacheFilesSize(_ complte: @escaping CacheSizeCompleteClosure) {
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first?.appending("/\(WBAlConfig.shared.cacheFileName)")
        guard let filePath = path else {
            complte(0)
            return
        }
        forderSize(with: filePath, complete: complte)
    }
    
// MARK: - Remove Cache and Download Files
    
///=============================================================================
/// @name Remove Cache and Download Files
///=============================================================================

    /// Remove all the downloaded file, or the name of the specified file
    ///
    /// - Parameters:
    ///   - name: need to remove the name of the file. Don't pass parameters, to remove all the downloaded file by default
    ///   - complete: when remove completed, closure will be used. if not set, the files will remove in background.
    public func removeDownloadFiles(with name: String? = nil, complete: CacheSizeCleanClosure? = nil) {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/\(WBAlConfig.shared.downFileName)")
        guard let filePath = path else { return }
        if let name = name {
            removeForder(with: filePath + "/" + name, complete: nil)
            complete?(true)
            return
        }
        removeForder(with: filePath, complete: complete)
    }

    /// To remove a single or all the cache files
    ///
    /// - Parameters:
    ///   - request: need to remove the cache file request. Don't pass this parameter, the default to remove all the cache files
    ///   - complete: when remove completed, closure will be used. if not set, the files will remove in background.
    public func removeCacheFiles(for request: WBAlRequest? = nil, complete: CacheSizeCleanClosure? = nil) {
        if let request = request {
            removeForder(with: cacheFilePath(request), complete: nil)
            removeForder(with: cacheMetadataFilePath(request), complete: nil)
            complete?(true)
            return
        }
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first?.appending("/\(WBAlConfig.shared.cacheFileName)")
        guard let filePath = path else {
            complete?(false)
            return
        }
        removeForder(with: filePath, complete: complete)
    }

    /// Remove all files
    ///
    /// - Parameter complte: when remove completed, closure will be used. if not set, the files will remove in background.
    public func removeAllFiles(_ complte: @escaping CacheSizeCleanClosure) {
        removeDownloadFiles { (_) in
            self.removeCacheFiles(complete: complte)
        }
    }

// MARK: - Cache File Path
    
///=============================================================================
/// @name Cache File Path
///=============================================================================
    
    /// Access to the path of the cache file
    ///
    /// - Parameter request: Need to get the cache the request of the path
    /// - Returns: The cache file path
    public func cacheFilePath(_ request: WBAlRequest) -> String {
        let cacheName = "/" + self.cacheFileName(request)
        let cachePath = self.cacheBasePath(request)
        return cachePath.appending(cacheName)
    }
    
    /// Take the path of the metadata file
    ///
    /// - Parameter request: Need to get the metadata file path of the request
    /// - Returns: The path of the metadata file
    public func cacheMetadataFilePath(_ request: WBAlRequest) -> String {
        let metaName = "/" + self.cacheFileName(request) + ".metadata"
        let metaPath = self.cacheBasePath(request)
        return metaPath.appending(metaName)
    }

// MARK: - Private
    
///=============================================================================
/// @name Private
///=============================================================================
    
    /// The name of the cache file
    private func cacheFileName(_ request: WBAlRequest) -> String {
        let requestURL = request.requestURL
        let baseURL = WBAlConfig.shared.baseURL
        var requestInfo = String(format: "Host:%@, Url:%@, Method:%@", baseURL, requestURL, request.requestMethod.rawValue.rawValue)
        if let params = request.requestParams {
            let params = request.cacheFileNameFilterForRequestParams(params)
            requestInfo = requestInfo.appendingFormat(", Params:%@", params)
        }
        let cacheFileName = WBAlUtils.md5WithString(requestInfo)
        return cacheFileName
    }
    
    /// The path of the cache file
    private func cacheBasePath(_ request: WBAlRequest) -> String {
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
        var cachePath = path.appending("/" + WBAlConfig.shared.cacheFileName)
        
        // Filter cache dirPath if needed
        let filters = WBAlConfig.shared.cacheDirPathFilters
        if !filters.isEmpty {
            for filter in filters {
                cachePath = filter.filterCacheDirPath(cachePath, baseRequest: request)
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
    
    private func createBaseCachePath(_ path: String) {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            WBAlUtils.addNotBackupAttribute(path)
        } catch let reason {
            WBALog("Create cache directory failed, reason = \"\(reason.localizedDescription)\"")
        }
    }

    /// Remove the entire contents of a folder
    ///
    /// - Parameters:
    ///   - filePath: need to remove the folder
    ///   - complete: whether remove complete
    private func removeForder(with filePath: String, complete: CacheSizeCleanClosure?) {
        let manager = FileManager.default
        if !manager.fileExists(atPath: filePath, isDirectory: nil) {
            DispatchQueue.main.async {
                complete?(false)
            }
            return
        }
        DispatchQueue.wbCurrent.async {
            let filePaths = manager.subpaths(atPath: filePath)
            filePaths?.forEach {
                let fileAbsoluePath = filePath + "/" + $0
                do {
                    try manager.removeItem(atPath: fileAbsoluePath)
                }catch let error {
                    WBALog("Remove Failed! remove file failed from \(fileAbsoluePath) with reason is: \(error.localizedDescription)")
                }
            }
            DispatchQueue.main.async {
                complete?(true)
            }
        }
    }

    /// Calculate the size of the folder
    ///
    /// - Parameters:
    ///   - filePath: the folder path
    ///   - complete: all the file's size
    private func forderSize(with filePath: String, complete: @escaping CacheSizeCompleteClosure) -> Void {
        let manager = FileManager.default
        if !manager.fileExists(atPath: filePath, isDirectory: nil) {
            complete(0)
            return
        }
        DispatchQueue.wbCurrent.async {
            let filePaths = manager.subpaths(atPath: filePath)
            var size: Double = 0
            filePaths?.forEach {
                let fileAbsoluePath = filePath + "/" + $0
                size += self.sizeOfFilePath(path: fileAbsoluePath)
            }
            DispatchQueue.main.async {
                complete(size)
            }
        }
    }
    
    /// A single file size
    ///
    /// - Parameter path: The file path
    /// - Returns: Access to the file size
    private func sizeOfFilePath(path: String) -> Double {
        let manager = FileManager.default
        if !manager.fileExists(atPath: path) { return 0 }
        do {
            let dic = try manager.attributesOfItem(atPath: path)
            if let size = dic[.size] as? Double { return size }
            return 0
        } catch { return 0 }
    }
}

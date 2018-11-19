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

    public typealias CacheSizeCompleteClosure = (_ size: UInt) -> Void
    public typealias CacheSizeCleanClosure = (_ complete: Bool) -> Void

    private let manager = FileManager.default
    
// MARK: - Cache and Download Files Size
    
///=============================================================================
/// @name Cache and Download Files Size
///=============================================================================
    
    /// 所有下载文件的大小.
    /// The download files size.
    ///
    /// - Parameter complete: calculate the download file size with closure
    public func downloadCacheSize(_ complete: @escaping CacheSizeCompleteClosure) {

        DispatchQueue.wbCurrent.async {

            var path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            path = (path as NSString).appendingPathComponent(WBAlConfig.shared.downFileName)

            let size = self.travelCacheFiles(path)

            DispatchQueue.main.async {
                complete(size)
            }
        }
    }
    
    /// 所有缓存文件的大小.
    /// The cache files size.
    ///
    /// - Parameter complte: calculate the response cache file size with closure
    public func responseCacheFilesSize(_ complte: @escaping CacheSizeCompleteClosure) {

        DispatchQueue.wbCurrent.async {

            var path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            path = (path as NSString).appendingPathComponent(WBAlConfig.shared.cacheFileName)

            let size = self.travelCacheFiles(path)

            DispatchQueue.main.async {
                complte(size)
            }
        }

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
        var path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        path = (path as NSString).appendingPathComponent(WBAlConfig.shared.downFileName)
        if let name = name {
            do {
                let path = (path as NSString).appendingPathComponent(name)
                try manager.removeItem(atPath: path)
                complete?(true)
            } catch { complete?(false) }
            return
        }
        do {
            try manager.removeItem(atPath: path)
            try manager.createDirectory(atPath: path, withIntermediateDirectories: true)
            complete?(true)
        } catch { complete?(false) }
    }

    /// To remove a single or all the cache files
    ///
    /// - Parameters:
    ///   - request: need to remove the cache file request. Don't pass this parameter, the default to remove all the cache files
    ///   - complete: when remove completed, closure will be used. if not set, the files will remove in background.
    public func removeCacheFiles(for request: WBAlRequest? = nil, complete: CacheSizeCleanClosure? = nil) {
        if let request = request {
            let cachePath = cacheFilePath(request)
            let metadataPath = cacheMetadataFilePath(request)
            do {
                try manager.removeItem(atPath: cachePath)
                try manager.removeItem(atPath: metadataPath)
                complete?(true)
            } catch { complete?(false) }
            return
        }
        var path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        path = (path as NSString).appendingPathComponent(WBAlConfig.shared.cacheFileName)

        do {
            try manager.removeItem(atPath: path)
            try manager.createDirectory(atPath: path, withIntermediateDirectories: true)
            complete?(true)
        } catch { complete?(false) }
    }

    /// Remove all files
    ///
    /// - Parameter complte: when remove completed, closure will be used. if not set, the files will remove in background.
    public func removeAllFiles(_ complte: @escaping CacheSizeCleanClosure) {
        removeDownloadFiles { (finised) in
            if finised {
                self.removeCacheFiles(complete: complte)
            } else {
                complte(false)
            }
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
        let cacheName = self.cacheFileName(request)
        let cachePath = self.cacheBasePath(request) as NSString
        return cachePath.appendingPathComponent(cacheName)
    }
    
    /// Take the path of the metadata file
    ///
    /// - Parameter request: Need to get the metadata file path of the request
    /// - Returns: The path of the metadata file
    public func cacheMetadataFilePath(_ request: WBAlRequest) -> String {
        let metaName = self.cacheFileName(request) + ".metadata"
        let metaPath = self.cacheBasePath(request) as NSString
        return metaPath.appendingPathComponent(metaName)
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
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        var cachePath = (path as NSString).appendingPathComponent(WBAlConfig.shared.cacheFileName)
        
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
        } catch {
            WBAlog("Create cache directory failed, reason = \(error)")
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
                let fileAbsoluePath = (filePath as NSString).appendingPathComponent($0)
                do {
                    try manager.removeItem(atPath: fileAbsoluePath)
                }catch let error {
                    WBAlog("Remove Failed! remove file failed from \(fileAbsoluePath) with reason is: \(error.localizedDescription)")
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
                let fileAbsoluePath = (filePath as NSString).appendingPathComponent($0)
                size += self.sizeOfFilePath(path: fileAbsoluePath)
            }
            DispatchQueue.main.async {
                complete(UInt(size))
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

    private func travelCacheFiles(_ path: String) -> UInt {
        let url = URL(fileURLWithPath: path)

        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .contentAccessDateKey, .totalFileAllocatedSizeKey]

        var diskCacheSize: UInt = 0

        var urls = [URL]()
        do {
            urls = try manager.contentsOfDirectory(at: url, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)
        } catch  { }

        for fileURL in urls {

            do {

                let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
                if resourceValues.isDirectory == true {
                    continue
                }

                if let size = resourceValues.totalFileAllocatedSize {
                    diskCacheSize += UInt(size)
                }
            } catch {}
        }

        return diskCacheSize
    }
}

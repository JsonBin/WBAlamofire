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
    
// MARK: - Cache and Download Files Size
    
///=============================================================================
/// @name Cache and Download Files Size
///=============================================================================
    
    /// 所有下载文件的大小.
    /// The download files size.
    public var downloadCacheSize: Double {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/\(WBAlConfig.shared.downFileName)")
        guard let filePath = path else { return 0}
        return forderSize(with: filePath)
    }
    
    /// 所有缓存文件的大小.
    /// The cache files size.
    public var responseCacheFilesSize: Double {
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first?.appending("/\(WBAlConfig.shared.cacheFileName)")
        guard let filePath = path else { return 0}
        return forderSize(with: filePath)
    }
    
// MARK: - Remove Cache and Download Files
    
///=============================================================================
/// @name Remove Cache and Download Files
///=============================================================================
    
    /// Remove all the downloaded file, or the name of the specified file
    ///
    /// - Parameter name: need to remove the name of the file. Don't pass parameters, to remove all the downloaded file by default
    public func removeDownloadFiles(with name: String? = nil) {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/\(WBAlConfig.shared.downFileName)")
        guard let filePath = path else { return }
        if let name = name {
            removeForder(with: filePath + "/" + name)
            return
        }
        removeForder(with: filePath)
    }
    
    /// To remove a single or all the cache files
    ///
    /// - Parameter request: need to remove the cache file request. Don't pass this parameter, the default to remove all the cache files
    public func removeCacheFiles(for request: WBAlRequest? = nil) {
        if let request = request {
            removeForder(with: cacheFilePath(request))
            removeForder(with: cacheMetadataFilePath(request))
            return
        }
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first?.appending("/\(WBAlConfig.shared.cacheFileName)")
        guard let filePath = path else { return}
        removeForder(with: filePath)
    }
    
    /// Remove all files
    public func removeAllFiles() {
        removeDownloadFiles()
        removeCacheFiles()
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
    /// - Parameter filePath: Need to remove the folder
    private func removeForder(with filePath: String) {
        let manager = FileManager.default
        if !manager.fileExists(atPath: filePath, isDirectory: nil) { return }
        let filePaths = manager.subpaths(atPath: filePath)
        filePaths?.forEach {
            let fileAbsoluePath = filePath + "/" + $0
            do {
                try manager.removeItem(atPath: fileAbsoluePath)
            }catch let error {
                WBALog("Remove Failed! remove file failed from \(fileAbsoluePath) with reason is: \(error.localizedDescription)")
            }
        }
    }
    
    /// Calculate the size of the folder
    ///
    /// - Parameter filePath: The folder path
    /// - Returns: The folder size
    private func forderSize(with filePath: String) -> Double {
        let manager = FileManager.default
        if !manager.fileExists(atPath: filePath, isDirectory: nil) {
            return 0
        }
        let filePaths = manager.subpaths(atPath: filePath)
        var size: Double = 0
        filePaths?.forEach {
            let fileAbsoluePath = filePath + "/" + $0
            size += sizeOfFilePath(path: fileAbsoluePath)
        }
        return size
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

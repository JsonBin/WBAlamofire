//
//  WBAlCache.swift
//  WBAlamofire
//
//  Created by zwb on 2017/12/27.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation

/// 缓存处理类
public struct WBAlCache {
    
    public static let shared = WBAlCache()
    
    // MARK: - Cache & Download Files Size
    
    /// The download files size. 所有下载文件的大小
    public var downloadCacheSize: Double {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/\(WBAlConfig.shared.downFileName)")
        guard let filePath = path else { return 0}
        return forderSize(with: filePath)
    }
    
    /// The cache files size. 所有缓存文件的大小
    public var cacheFilesSize: Double {
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first?.appending("/\(WBAlConfig.shared.cacheFileName)")
        guard let filePath = path else { return 0}
        return forderSize(with: filePath)
    }
    
    // MARK: - Remove Cache & Download Files
    
    /// 移除所有的下载文件或指定名字的文件
    ///
    /// - Parameter name: 需要移除的文件的名字. 不传参数，默认为移除所有的下载文件
    public func removeDownloadFiles(with name: String? = nil) {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/\(WBAlConfig.shared.downFileName)")
        guard let filePath = path else { return }
        if let name = name {
            removeForder(with: filePath + "/" + name)
            return
        }
        removeForder(with: filePath)
    }
    
    /// 移除单个或所有的缓存文件
    ///
    /// - Parameter request: 需要移除缓存文件的request.不传此参数，默认为移除所有的缓存文件
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
    
    /// 移除所有的文件
    public func removeAllFiles() {
        removeDownloadFiles()
        removeCacheFiles()
    }
    
    // MARK: - Cache File Path
    
    /// 获取缓存文件的路径
    ///
    /// - Parameter request: 需要获取缓存路径的request
    /// - Returns: 缓存文件路径
    public func cacheFilePath(_ request: WBAlRequest) -> String {
        let cacheName = "/" + self.cacheFileName(request)
        let cachePath = self.cacheBasePath(request)
        return cachePath.appending(cacheName)
    }
    
    /// 获取metadata文件的路径
    ///
    /// - Parameter request: 需要获取metadata文件路径的request
    /// - Returns: metadata文件的路径
    public func cacheMetadataFilePath(_ request: WBAlRequest) -> String {
        let metaName = "/" + self.cacheFileName(request) + ".metadata"
        let metaPath = self.cacheBasePath(request)
        return metaPath.appending(metaName)
    }
    
    /// 缓存文件的名字
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
    
    /// 缓存文件的路径
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
    
    // MARK: - File Dely
    
    /// 移除文件夹内的所有内容
    ///
    /// - Parameter filePath: 需要移除的文件夹
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
    
    /// 计算文件夹的大小
    ///
    /// - Parameter filePath: 文件夹路径
    /// - Returns: 文件夹大小
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
    
    /// 计算单个文件大小
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 获取文件大小
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

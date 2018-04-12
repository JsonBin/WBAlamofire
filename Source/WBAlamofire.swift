//
//  WBAlmofire.swift
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

///  WBAlamofire is the underlying class that handles actual request generation,
///  serialization and response handling.
public final class WBAlamofire {
    
    ///  Get the shared.
    public static let shared = WBAlamofire()
    
// MARK: - Private Properties
    
///=============================================================================
/// @name Private Properties
///=============================================================================
    
    private let _manager: SessionManager
    private let _config: WBAlConfig
    private let _lock: NSLock
    private let _asyncQueue: DispatchQueue
    private let _statusCode: [Int]
    private let _contentType: [String]
    private var _requestRecord:[Int: WBAlBaseRequest]
    private let WBAlRequestErrorDomain = "com.wbalamofire.request.domain"
    private let WBAlRequestNetWorkErrorCode = -9   // 无网络链接错误状态码
    private let WBAlRequestErrorCode = -10   // 失败处理状态码
#if !os(watchOS)
    private let _listenManager: NetworkReachabilityManager?
#endif
#if os(iOS)
    /// Add: load view
    private let _loadView: WBActivityIndicatorView
#endif
    
// MARK: - Init and Reqest
    
///=============================================================================
/// @name Init and Reqest
///=============================================================================
    
    public init() {
        _config = WBAlConfig.shared
        _config.sessionConfiguration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        _config.sessionConfiguration.timeoutIntervalForResource = _config.requestTimeoutInterval
        _config.sessionConfiguration.timeoutIntervalForRequest = _config.requestTimeoutInterval
        _config.sessionConfiguration.allowsCellularAccess = _config.allowsCellularAccess
        
        _manager = SessionManager(configuration: _config.sessionConfiguration, serverTrustPolicyManager: _config.serverPolicy)
        _lock = NSLock()
        _asyncQueue = DispatchQueue.wbCurrent
        _statusCode = _config.statusCode
        _contentType = _config.acceptType
        _requestRecord = [Int: WBAlBaseRequest]()
        
        #if !os(watchOS)
            _listenManager = NetworkReachabilityManager(host: "www.apple.com")
        #endif
        
        #if os(iOS)
            _loadView = WBActivityIndicatorView()
            refreshLoadViewStatus()
        #endif
    }
    
    /// Add request to session and start it.
    /// 添加网络请求
    ///
    /// - Parameter request: Class from WBALBaseRequest
    public func add(_ request: WBAlBaseRequest) -> Void {
        
        #if !os(watchOS)
            if let listenManager = _listenManager, !listenManager.isReachable {
                WBALog("NetWork Error!, the \(request)'s network is unReachable.")
                let error = NSError(domain: WBAlRequestErrorDomain, code: WBAlRequestNetWorkErrorCode, userInfo: [NSLocalizedDescriptionKey:"Network is unReachable."])
                requestDidFailed(request, error: error)
                return
            }
            
            _listenManager?.listener = { status in
                if status == .unknown {
                    // When the Network status is Unknown.
                    WBAlamofire.shared.cancel(request)
                    self.setNetworkActivityIndicatorVisible(false)
                }else if status == .notReachable {
                    // When the Network notReachable.
                    WBAlamofire.shared.cancel(request)
                    self.setNetworkActivityIndicatorVisible(false)
                }
            }
        #endif
        if _config.listenNetWork {
            // Show the Network status in status bar.
            setNetworkActivityIndicatorVisible()
            
            #if !os(watchOS)
                _listenManager?.startListening()
            #endif
        }
        
        let request = request
        if let customRequest = request.buildCustomRequest {
            let dataRequest = _manager.request(customRequest)
            // add the user and password if use https or server need.
            if let auths = request.requestAuthHeaders {
                dataRequest.authenticate(user: auths.first!, password: auths.last!)
            }
            // set the validator response code and type.
            dataRequest.validate(statusCode: _statusCode)
            dataRequest.validate(contentType: _contentType)
            requestResponse(request, dataRequest: dataRequest)
            request.request = dataRequest
        }else {
            // return type and closure. if upload data, it will reponse closure, Otherwise will return Request.
            request.request = sessionRequest(request, closure: { [unowned self] (uploadRequest, error) in
                if let error = error {
                    self.requestDidFailed(request, error: error)
                    return
                }else {
                    request.request = uploadRequest
                    
                    self.requestSetTaskPriority(request)
                }
            })
        }
        
        self.requestSetTaskPriority(request)
    }

    /// Cancel a request that was previously added.
    /// 取消网络请求
    ///
    /// - Parameter request: Class from WBAlBaseRequest
    public func cancel(_ request: WBAlBaseRequest) -> Void {
        if !request.resumableDownloadPath.isEmpty {
            // if is downloadtask, this request will save the resume data
            // to resumabledownloadpath in temp library before cancel.
            // otherwise cancel the request task.
            if let down = request.request?.task as? URLSessionDownloadTask {
                down.cancel(byProducingResumeData: { (data) in
                    let path = self.downloadTempPathForDownloadPath(request.resumableDownloadPath)
                    do {
                        try data?.write(to: path, options: .atomic)
                    } catch let error {
                        WBALog("Cancel Request ResumeData Save Failed!, save resumeData failed. reason:\"\(error.localizedDescription)\"")
                    }
                })
            }
        }else{
            request.request?.cancel()
        }
        removeRecord(forRequest: request)
        request.clearCompleteClosure()
     
        if _requestRecord.isEmpty {
            #if !os(watchOS)
                _listenManager?.stopListening()
            #endif
            
            // cancel net work status
            setNetworkActivityIndicatorVisible(false)
        }
    }
    
    ///  取消所有网络请求
    ///  Cancel all requests that were previously added.
    public func cancelAllRequest() -> Void {
        #if !os(watchOS)
            _listenManager?.stopListening()
        #endif
        
        _lock.lock()
        let keys = _requestRecord.keys
        _lock.unlock()
        keys.forEach {
            _lock.lock()
            let request = _requestRecord[$0]
            _lock.unlock()
            
            request?.stop()
        }
        
        // cancel net work status
        setNetworkActivityIndicatorVisible(false)
    }

    /// Return the constructed URL of request.
    ///
    /// - Parameter request: The request to parse. Should not be nil.
    /// - Returns: The result URL.
    public func buildURL(_ request: WBAlBaseRequest) -> URLConvertible {
        var detailUrl = request.requestURL
        if !detailUrl.isEmpty {
            var temp: URL!
            do {
                temp = try detailUrl.asURL()
                // if detailURL is vaid URL
                if let _ = temp.host, let _ = temp.scheme { return detailUrl  }
            }catch { WBALog("Error! the \(detailUrl) is not use as to url") }
        }
        
        // Filter url is needed
        let filters = _config.urlFilters
        if !filters.isEmpty {
            filters.forEach {
                detailUrl = $0.filterURL(detailUrl, baseRequest: request)
            }
        }
        
        // Base URL
        let baseURL: String
        if request.useCDN {
            if !request.cdnURL.isEmpty {
                baseURL = request.cdnURL
            }else{
                baseURL = _config.cdnURL
            }
        }else{
            if !request.baseURL.isEmpty {
                baseURL = request.baseURL
            }else{
                baseURL = _config.baseURL
            }
        }
        
        // url
        var url: URL?
        do { url = try baseURL.asURL() } catch {}
        
        if detailUrl.isEmpty {
            return url ?? ""
        }
        
        if !baseURL.isEmpty && !baseURL.hasPrefix("/") {
            url = url?.appendingPathComponent("")
        }
        
        return URL(string: detailUrl, relativeTo: url)?.absoluteString ?? detailUrl
    }
  
// MARK: - Request Set Priority
    
///=============================================================================
/// @name Request Set Priority
///=============================================================================
    
    /// Set the request task priority
    private func requestSetTaskPriority(_ request: WBAlBaseRequest) {
        if let dataRequest = request.request {
            // set the request task priority
            // !!Available on iOS 8 +
            if let priority = request.priority {
                switch priority {
                case .default:
                    dataRequest.task?.priority = URLSessionTask.defaultPriority
                case .low:
                    dataRequest.task?.priority = URLSessionTask.lowPriority
                case .high:
                    dataRequest.task?.priority = URLSessionTask.highPriority
                }
            }
            
            // retain request
            WBALog("Add Request: \(request)")
            self.addRecord(request)
            dataRequest.resume()
            
            #if os(iOS)
                // if download file, not to show load view
                if !request.resumableDownloadPath.isEmpty { return }
                // update the loadView status
                refreshLoadViewStatus()
                // Whether show load view
                if let view = WBAlUtils.wb_getCurrentViewController?.view, request.showLoadView {
                    // set the load view's properties from the request settting.
                    _loadView.setActivityLabel(text: request.showLoadText, font: request.showLoadTextFont, color: request.showLoadTextColor)
                    if let type = request.showLoadAnimationType { _loadView.animationType = type }
                    if let position = request.showLoadTextPosition { _loadView.labelPosition = position }
                    // show the load view in main thread
                    DispatchQueue.main.async {
                        self._loadView.startAnimation(inView: view)
                    }
                }
            #endif
        }
    }
    
    /// Reset the loadView status only in iOS.
    private func refreshLoadViewStatus() {
        #if os(iOS)
        _loadView.labelPosition = _config.loadViewTextPosition
        _loadView.animationType = _config.loadViewAnimationType
        _loadView.setActivityLabel(text: _config.loadViewText, font: _config.loadViewTextFont, color: _config.loadViewTextColor)
        #endif
    }
    
    /// Show and hide the Network status.
    ///
    /// - Parameter show: whether show or hide.
    private func setNetworkActivityIndicatorVisible(_ show: Bool = true) {
        // in iOS, show and hide the network status.
        #if os(iOS)
            UIApplication.shared.isNetworkActivityIndicatorVisible = show
        #endif
    }
    
 // MARK: - Init Request
    
///=============================================================================
/// @name Init Request
///=============================================================================
    
    private func sessionRequest(_ request:WBAlBaseRequest, closure dataClosure: dataRequestClosure? = nil) -> Request? {
        let method = request.requestMethod
        let url = buildURL(request)
        
        let addRequest: Request?
        switch method {
        case .get:
            if !request.resumableDownloadPath.isEmpty {
                // download || resumeDownload
                addRequest = download(request, url: url)
            }else{
                // get request
                addRequest = setRequest(request, url: url)
            }
        default:
            addRequest = setRequest(request, url: url, closure: dataClosure)
        }
        return addRequest
    }
    
// MARK: - Data Request
    
///=============================================================================
/// @name Data Request
///=============================================================================

    private typealias dataRequestClosure = (_ request:DataRequest?, _ error:Error? ) -> Void
    private func setRequest(_ request:WBAlBaseRequest, url urlString:URLConvertible, closure dataClosure: dataRequestClosure? = nil)  -> DataRequest? {
        var setRe: DataRequest?
        if let closure = request.requestDataClosure {
            var uploadError: Error? = nil
           _manager.upload(multipartFormData: closure, to: urlString, method: request.requestMethod.rawValue, headers: request.requestHeaders, encodingCompletion: { (result) in
            switch result {
            case .success(let upload, _, _):
                // add the user and password if use https or server need.
                if let auths = request.requestAuthHeaders {
                    upload.authenticate(user: auths.first!, password: auths.last!)
                }
                upload.uploadProgress(closure: { (progress) in
                    if let uploadProgressHandler = request.downloadProgress {
                        uploadProgressHandler(progress)
                    }
                })
                // set the validator response code and type.
                upload.validate(statusCode: self._statusCode)
                upload.validate(contentType: self._contentType)
                
                // response
                self.requestResponse(request, dataRequest: upload)
                setRe = upload
            case .failure(let error):
                uploadError = NSError(domain: self.WBAlRequestErrorDomain, code: self.WBAlRequestErrorCode, userInfo: [NSLocalizedDescriptionKey:error.localizedDescription])
            }
            // closure
            if let closure = dataClosure {
                closure(setRe, uploadError)
            }
            })
        }else{
            if let fileURL = request.uploadFile {
                setRe = _manager.upload(fileURL, to: urlString, method: request.requestMethod.rawValue, headers: request.requestHeaders)
            }else if let data = request.uploadData {
                setRe = _manager.upload(data, to: urlString, method: request.requestMethod.rawValue, headers: request.requestHeaders)
            }else{
                setRe = _manager.request(urlString, method: request.requestMethod.rawValue, parameters: request.requestParams, encoding: request.paramEncoding.rawValue, headers: request.requestHeaders)
            }
            // add the user and password if use https or server need.
            if let user = request.requestAuthHeaders?.first, let pas = request.requestAuthHeaders?.last {
                setRe?.authenticate(user: user, password: pas)
            }
            // set the validator response code and type.
            setRe?.validate(statusCode: _statusCode)
            setRe?.validate(contentType: _contentType)
            
            // response
            requestResponse(request, dataRequest: setRe)
        }
        
        return setRe
    }
    
// MARK: - Download Request
    
///=============================================================================
/// @name Download Request
///=============================================================================
    
    private func download(_ request:WBAlBaseRequest, url urlString:URLConvertible) -> DownloadRequest {
        var downpath = request.resumableDownloadPath
        let manager = FileManager.default
        var isDirectory: ObjCBool = true
        if !manager.fileExists(atPath: downpath, isDirectory: &isDirectory) {
            isDirectory = false
        }
        
        // jude if is directory
        if isDirectory.boolValue {
            let fileName = try? urlString.asURL().lastPathComponent
            downpath = downpath.appending(fileName ?? "")
        }
        // load the cache data, is not exists, the data is nil.
        let cacheURL = formatDownloadPathWithMd5String(downpath, useMD5: isDirectory.boolValue)
        if !downpath.isEmpty {
            do {
                try _ = Data(contentsOf: cacheURL)
            } catch {
                WBALog("Read Error! \(downpath) data is nil. Need to download again.")
            }
        }
        // if need to download again, remove the exist file before start
        // download task.
        if manager.fileExists(atPath: cacheURL.path) {
            try? manager.removeItem(atPath: cacheURL.path)
        }
        let tmp = downloadTempPathForDownloadPath(downpath)
        let resumeFileExisits = manager.fileExists(atPath: tmp.path)
        var data: Data?
        do {
            data = try Data(contentsOf: tmp)
        } catch {
            WBALog("Resume Data Error! \(tmp) resume data is nil.")
        }
        let resumeDataVaild = WBAlUtils.validataResumeData(data)
        
        let destionation: DownloadRequest.DownloadFileDestination = { _,_ in
            return (cacheURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        // create request
        let downRequest: DownloadRequest
        // if file exist and the resumeData is vaildator
        if resumeFileExisits, resumeDataVaild, let data = data {
            // download with resumeData
            downRequest = _manager.download(resumingWith: data, to: destionation)
        }else{
            downRequest = _manager.download(urlString, parameters: request.requestParams, encoding: request.paramEncoding.rawValue, headers: request.requestHeaders, to: destionation)
        }
        // add the user and password if use https or server need.
        if let user = request.requestAuthHeaders?.first, let pas = request.requestAuthHeaders?.last {
            downRequest.authenticate(user: user, password: pas)
        }
        downRequest.downloadProgress { (progress) in
            if let progressHandler = request.downloadProgress {
                progressHandler(progress)
            }
        }
        // set the validator response code and type.
        downRequest.validate(statusCode: _statusCode)
        downRequest.validate(contentType: _contentType)
        // response
        requestResponse(request, downRequest: downRequest, cacheURL: tmp)
        
        return downRequest
    }
    
// MARK: - DataRequest and DownRequest Response
    
///=============================================================================
/// @name DataRequest and DownRequest Response
///=============================================================================
    
    private func requestResponse(_ request:WBAlBaseRequest, dataRequest dataRe:DataRequest?) {
        // Corresponding to the return type for processing
        switch request.responseType {
        case .default:
            dataRe?.response(completionHandler: { (response) in
                request.responseData = response.data
                if let error = response.error {
                    self.requestDidFailed(request, error: error)
                }else{
                    self.requestSuccess(request, requestResult: response.data)
                }
            })
        case .json:
            dataRe?.responseJSON(completionHandler: { (response) in
                request.responseData = response.data
                switch response.result {
                case .success(let value):
                    self.requestSuccess(request, requestResult: value)
                case .failure(let error):
                    // When response type is json, you can check the server's error infomation.
                    // The error log has contain response and other string. Otherwise, that only has
                    // response information.
                    if let data = response.data, let jsonString = String(data: data, encoding: .utf8) {
                        WBALog("Request Failed:................................................>\n Response:\(response) \n//////////////////////////////////////////////////////////////////////////\n Data:\(jsonString)")
                    }else {
                        WBALog("Request Failed:......................> \(response)")
                    }
                    self.requestDidFailed(request, error: error)
                }
            })
        case .data:
            dataRe?.responseData(completionHandler: { (response) in
                request.responseData = response.data
                switch response.result {
                case .success(let value):
                    self.requestSuccess(request, requestResult: value)
                case .failure(let error):
                    self.requestDidFailed(request, error: error)
                }
            })
        case .string:
            dataRe?.responseString(completionHandler: { (response) in
                request.responseData = response.data
                switch response.result {
                case .success(let value):
                    self.requestSuccess(request, requestResult: value)
                case .failure(let error):
                    self.requestDidFailed(request, error: error)
                }
            })
        case .plist:
            dataRe?.responsePropertyList(completionHandler: { (response) in
                request.responseData = response.data
                switch response.result {
                case .success(let value):
                    self.requestSuccess(request, requestResult: value)
                case .failure(let error):
                    self.requestDidFailed(request, error: error)
                }
            })
        }
    }
    
    private func requestResponse(_ request:WBAlBaseRequest, downRequest downRe:DownloadRequest, cacheURL url: URL) {
        // Corresponding to the return type for processing
        switch request.responseType {
        case .default:
            downRe.response(completionHandler: { (response) in
                request.responseData = response.resumeData
                if let error = response.error {
                    self.requestDidFailed(request, error: error, cacheURL: url, resumeData: response.resumeData)
                }else{
                    self.requestSuccess(request, requestResult: response.destinationURL)
                }
            })
        case .json:
            downRe.responseJSON(completionHandler: { (response) in
                request.responseData = response.resumeData
                switch response.result {
                case .success(let value):
                    self.requestSuccess(request, requestResult: value)
                case .failure(let error):
                    self.requestDidFailed(request, error: error, cacheURL: url, resumeData: response.resumeData)
                }
            })
        case .data:
            downRe.responseData(completionHandler: { (response) in
                request.responseData = response.resumeData
                switch response.result {
                case .success(let value):
                    self.requestSuccess(request, requestResult: value)
                case .failure(let error):
                    self.requestDidFailed(request, error: error, cacheURL: url, resumeData: response.resumeData)
                }
            })
        case .string:
            downRe.responseString(completionHandler: { (response) in
                request.responseData = response.resumeData
                switch response.result {
                case .success(let value):
                    self.requestSuccess(request, requestResult: value)
                case .failure(let error):
                    self.requestDidFailed(request, error: error, cacheURL: url, resumeData: response.resumeData)
                }
            })
        case .plist:
            downRe.responsePropertyList(completionHandler: { (response) in
                request.responseData = response.resumeData
                switch response.result {
                case .success(let value):
                    self.requestSuccess(request, requestResult: value)
                case .failure(let error):
                    self.requestDidFailed(request, error: error, cacheURL: url, resumeData: response.resumeData)
                }
            })
        }
    }
    
// MARK: - MD5 and URL
    
///=============================================================================
/// @name MD5 and URL
///=============================================================================

    static var cacheFolder: String?
    private func formatDownloadPathWithMd5String(_ down: String, useMD5 use:Bool) -> URL {
        let md5String = use ? WBAlUtils.md5WithString(down) : down
        
        let manager = FileManager.default
        
        let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        if WBAlamofire.cacheFolder == nil {
            WBAlamofire.cacheFolder = (cacheDir as NSString).appendingPathComponent(WBAlConfig.shared.downFileName)
        }
        
        var isDirectory: ObjCBool = true
        if let path = WBAlamofire.cacheFolder, !manager.fileExists(atPath: path, isDirectory: &isDirectory) {
            isDirectory = false
        }
        
        if !isDirectory.boolValue {
            do {
                if let pathStr = WBAlamofire.cacheFolder {
                    try manager.createDirectory(atPath: pathStr, withIntermediateDirectories: true, attributes: nil)
                    WBAlUtils.addNotBackupAttribute(pathStr)
                }
            } catch {
                WBALog("Down Failed! Create cache directory at \(WBAlamofire.cacheFolder ?? "") is failed!")
                WBAlamofire.cacheFolder = nil
            }
        }

        if let folder = WBAlamofire.cacheFolder {
            let path = (folder as NSString).appendingPathComponent(md5String)
            return URL(fileURLWithPath: path)
        }
        
        return URL(fileURLWithPath: (cacheDir as NSString).appendingPathComponent(md5String))
    }
    
    // resume data url.
    private func downloadTempPathForDownloadPath(_ path: String) -> URL {
        let md5 = WBAlUtils.md5WithString(path)
        let manager = FileManager.default
        
        let cacheDir = NSTemporaryDirectory()
        let cacheFolder = (cacheDir as NSString).appendingPathComponent(WBAlConfig.shared.downFileName)
        
        var isDirectory: ObjCBool = true
        if !manager.fileExists(atPath: cacheFolder, isDirectory: &isDirectory) {
            isDirectory = false
        }
        
        if !isDirectory.boolValue {
            do {
                try manager.createDirectory(atPath: cacheFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                WBALog("Down Failed! Create cache directory at \(cacheFolder) is failed!")
            }
        }

        return URL(fileURLWithPath: (cacheFolder as NSString).appendingPathComponent(md5))
    }
    
// MARK: - Request Record
    
///=============================================================================
/// @name Request Record
///=============================================================================
    
    private func addRecord(_ request:WBAlBaseRequest) {
        _lock.lock()
        defer {
            _lock.unlock()
        }
        _requestRecord.updateValue(request, forKey: request.request?.task?.taskIdentifier ?? 0)
    }
    
    private func removeRecord(forRequest request:WBAlBaseRequest) {
        _lock.lock()
        defer {
            _lock.unlock()
        }
        if let _ = _requestRecord.removeValue(forKey: request.request?.task?.taskIdentifier ?? 0) {
            WBALog("Request<\(request)> remove from record!")
        }
    }
    
// MARK: - Request Success and Failure
    
///=============================================================================
/// @name Request Success and Failure
///=============================================================================

    private func requestDidFailed(_ request:WBAlBaseRequest, error requestError:Error, cacheURL url:URL? = nil, resumeData data:Data? = nil) {
        // Hide the Network status in status bar.
        setNetworkActivityIndicatorVisible(false)
        
        request.error = requestError
        WBALog("Request <\(request)> failed, status code = \(request.statusCode), error = \(requestError.localizedDescription)")
        
        // save incomplete down data
        if let data = data, let url = url {
            do {
                try data.write(to: url, options: .atomic)
            } catch let error {
                WBALog("Save Failed!, save resumeData failed. reason:\"\(error.localizedDescription)\"")
            }
        }
        
        autoreleasepool(invoking: {
            request.requestFailedPreprocessor()
        })
        
        DispatchQueue.main.async {
            request.totalAccessoriesWillStop()
            request.requestFailedFilter()
            
            if let delegate = request.delegate {
                delegate.requestFailed(request)
            }
            
            if let failure = request.failureCompleteClosure {
                failure(request)
            }
            
            request.totalAccessoriesDidStop()
            
            // remove request
            self.removeRecord(forRequest: request)
            request.clearCompleteClosure()
            
            #if os(iOS)
                // stop load view
                self._loadView.stopAnimation()
            #endif
        }
    }
    
    private func requestSuccess(_ request: WBAlBaseRequest, requestResult result:Any?) {
        // Hide the Network status in status bar.
        setNetworkActivityIndicatorVisible(false)
        
        if let result = result {
            // If it is to download the response returns the path of save for download
            if result is URL {
                request.downloadURL = result as? URL
            }else{
                switch request.responseType {
                case .json:
                    request.responseJson = result as? [String: Any]
                case .plist:
                    request.responsePlist = result
                case .string:
                    request.responseString = result as? String
                default:
                    request.responseObj = result
                    
                    if result is Data {
                        request.responseData = result as? Data
                        request.responseString = String(data: result as! Data, encoding: WBAlUtils.stringEncodingFromRequest(request))
                    }
                }
            }
        }
        
        if !request.statusCodeValidator {
            let error = NSError(domain: WBAlRequestErrorDomain, code: WBAlRequestErrorCode, userInfo: [NSLocalizedDescriptionKey:"Response code range out."])
            requestDidFailed(request, error: error)
        }else{
            autoreleasepool(invoking: {
                request.requestCompletePreprocessor()
            })
            
            DispatchQueue.main.async {
                request.totalAccessoriesWillStop()
                request.requestCompleteFilter()
                
                if let delegate = request.delegate {
                    delegate.requestFinish(request)
                }
                if let success = request.successCompleteClosure {
                    success(request)
                }
                
                request.totalAccessoriesDidStop()
            }
        }
        
        // remove request
        DispatchQueue.main.async {
            self.removeRecord(forRequest: request)
            request.clearCompleteClosure()
            
            #if os(iOS)
                // stop load view
                self._loadView.stopAnimation()
            #endif
        }
    }
}

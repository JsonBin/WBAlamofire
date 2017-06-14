//
//  WBAlmofire.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/24.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import UIKit

open class WBAlamofire {
    
    /// 实例化，唯一性
    open static let shared = WBAlamofire()
    
    // MARK: - Private Properties
    private var _listenManager: NetworkReachabilityManager?
    private var _manager: SessionManager
    private var _config: WBAlConfig
    private var _lock: NSLock
    private var _asyncQueue: DispatchQueue
    private var _statusCode = 0..<1
    /*private var _contentType: [String]*/
    private var _requestRecord:[Int: WBAlBaseRequest]
    private let WBAlRequestErrorDomain = "com.wbAlamofire.request.domain"
    private let WBAlRequestNetWorkErrorCode = -9   // 无网络链接错误状态码
    private let WBAlRequestErrorCode = -10   // 失败处理状态码
    
// MARK: - Init && Request
    public init() {
        _config = WBAlConfig.shared
        _config.sessionConfiguration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        _config.sessionConfiguration.timeoutIntervalForResource = _config.requestTimeoutInterval
        _config.sessionConfiguration.timeoutIntervalForRequest = _config.requestTimeoutInterval
        _config.sessionConfiguration.allowsCellularAccess = _config.allowsCellularAccess
        
        _listenManager = NetworkReachabilityManager(host: "www.apple.com")
        _manager = SessionManager(configuration: _config.sessionConfiguration, serverTrustPolicyManager: _config.serverPolicy)
        _lock = NSLock()
        _asyncQueue = DispatchQueue.WBALAsyncDispatchQueue
        _statusCode = _config.statusCode
        /*_contentType = ["application/json"]*/
        _requestRecord = [Int: WBAlBaseRequest]()
    }
    
    /// Add Request 添加网络请求
    ///
    /// - Parameter request: Class from WBALBaseRequest
    open func add(_ request:WBAlBaseRequest) -> Void {
        
        if let listenManager = _listenManager, !listenManager.isReachable {
            WBALog("NetWork Error!, the \(request)'s network is not reachable.")
            let error = NSError(domain: WBAlRequestErrorDomain, code: WBAlRequestNetWorkErrorCode, userInfo: [NSLocalizedDescriptionKey:"Network is unReachable."])
            requestDidFailed(request, error: error)
            return
        }
        
        _listenManager?.listener = { status in
            if status == .unknown {
                // 网络变为未知
                WBAlamofire.shared.cancel(request)
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }else if status == .notReachable {
                // 网络断开
                WBAlamofire.shared.cancel(request)
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
        if _config.listenNetWork {
            // 网络状态菊花显示
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            _listenManager?.startListening()
        }
        
        let request = request
        if let customRequest = request.buildCustomRequest {
            let dataRequest = _manager.request(customRequest)
            // 添加https的user以及password
            if let auths = request.requestAuthHeaders {
                dataRequest.authenticate(user: auths.first!, password: auths.last!)
            }
            // 设置响应code范围及返回类型
            dataRequest.validate(statusCode: _statusCode)
            /*dataRequest.validate(contentType: _contentType)*/
            requestResponse(request, dataRequest: dataRequest)
            request.request = dataRequest
        }else {
            // 返回和回调一起使用，如果是上传数据则走回调，否则返回Request
            request.request = sessionRequest(request, closure: { [unowned self] (uploadRequest, error) in
                if let error = error {
                    self.requestDidFailed(request, error: error)
                    return
                }else {
                    request.request = uploadRequest
                    
                    if let dataRequest = request.request {
                        // 对请求进行优先权赋值
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
                    }
                }
            })
        }
        
        if let dataRequest = request.request {
            // 对请求进行优先权赋值
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
        }
    }
    
    /// Cancel Request 取消网络请求
    ///
    /// - Parameter request: Class from WBAlBaseRequest
    open func cancel(_ request:WBAlBaseRequest) -> Void {
        if let request = request.request {
            request.task?.cancel()
        }
        removeRecord(forRequest: request)
        request.clearCompleteClosure()
     
        if _requestRecord.isEmpty {
            _listenManager?.stopListening()
            
            // 取消网络菊花状态
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    /// Cancel All Request 取消所有网络请求
    open func cancelAllRequest() -> Void {
        _listenManager?.stopListening()
        
        _lock.lock()
        let keys = _requestRecord.keys
        _lock.unlock()
        if !keys.isEmpty {
            for key in keys {
                _lock.lock()
                let request = _requestRecord[key]
                _lock.unlock()
                
                request?.stop()
            }
        }
        // 取消网络菊花状态
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    open func buildURL(_ request: WBAlBaseRequest) -> URLConvertible {
        var detailUrl = request.requestURL
        var temp: URL!
        do {
            temp = try detailUrl.asURL()
            // if detailURL is vaid URL
            if let _ = temp.host, let _ = temp.scheme { return detailUrl  }
        }catch { WBALog("Error! the \(detailUrl) is not use as to url") }
        
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
    
 // MARK: - Request
    
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
    
    
// MARK:  - DataRequest
    private typealias dataRequestClosure = (_ request:DataRequest?, _ error:Error? ) -> Void
    private func setRequest(_ request:WBAlBaseRequest, url urlString:URLConvertible, closure dataClosure: dataRequestClosure? = nil)  -> DataRequest? {
        var setRe: DataRequest?
        if let closure = request.requestDataClosure {
            var uploadError: Error? = nil
           _manager.upload(multipartFormData: closure, to: urlString, method: request.requestMethod, headers: request.requestHeaders, encodingCompletion: { (result) in
            switch result {
            case .success(let upload, _, _):
                // 添加https的user以及password
                if let auths = request.requestAuthHeaders {
                    upload.authenticate(user: auths.first!, password: auths.last!)
                }
                upload.uploadProgress(closure: { (progress) in
                    if let uploadProgressHandler = request.downloadProgress {
                        uploadProgressHandler(progress)
                    }
                })
                /// 设置响应code范围及返回类型
                upload.validate(statusCode: self._statusCode)
                /*upload.validate(contentType: self._contentType)*/
                
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
                setRe = _manager.upload(fileURL, to: urlString, method: request.requestMethod, headers: request.requestHeaders)
            }else if let data = request.uploadData {
                setRe = _manager.upload(data, to: urlString, method: request.requestMethod, headers: request.requestHeaders)
            }else{
                setRe = _manager.request(urlString, method: request.requestMethod, parameters: request.requestParams, encoding: request.paramEncoding, headers: request.requestHeaders)
            }
            // 添加https的user以及password
            if let auths = request.requestAuthHeaders {
                setRe?.authenticate(user: auths.first!, password: auths.last!)
            }
            // 设置响应code范围及返回类型
            setRe?.validate(statusCode: _statusCode)
            /*setRe.validate(contentType: _contentType)*/
            
            // response
            requestResponse(request, dataRequest: setRe)
        }
        
        return setRe
    }
    
// MARK: - Download Request
    
    private func download(_ request:WBAlBaseRequest, url urlString:URLConvertible) -> DownloadRequest {
        var data: Data?
        var downpath = request.resumableDownloadPath
        let manager = FileManager.default
        var isDirectory: ObjCBool = true
        if !manager.fileExists(atPath: downpath, isDirectory: &isDirectory) {
            isDirectory = false
        }
        
        // jude if is directory
        if isDirectory.boolValue {
            let fileName = try! urlString.asURL().lastPathComponent
            downpath = downpath.appending(fileName)
        }
        // load the cache data, is not exists, the data is nil.
        let cacheURL = formatDownloadPathWithMd5String(downpath, useMD5: isDirectory.boolValue)
        if !downpath.isEmpty {
            do {
                data = try Data(contentsOf: cacheURL, options: [.mappedIfSafe, .alwaysMapped])
            } catch {
                WBALog("Read Error! \(downpath) data is nil. Need to download again.")
            }
        }
        let destionation:DownloadRequest.DownloadFileDestination = { _,_ in
            return (cacheURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        // create request
        let downRequest: DownloadRequest
        if let data = data {
            // 断点续传功能
            downRequest = _manager.download(resumingWith: data, to: destionation)
        }else{
            downRequest = _manager.download(urlString, parameters: request.requestParams, encoding: request.paramEncoding, headers: request.requestHeaders, to: destionation)
        }
        // 添加https的user以及password
        if let auths = request.requestAuthHeaders {
            downRequest.authenticate(user: auths.first!, password: auths.last!)
        }
        downRequest.downloadProgress { (progress) in
            if let progressHandler = request.downloadProgress {
                progressHandler(progress)
            }
        }
        // 设置响应code范围及返回类型
        downRequest.validate(statusCode: _statusCode)
        /*downRequest.validate(contentType: ["application/json"])*/
        /*downRequest.validate(contentType: _contentType)*/
        // response
        requestResponse(request, downRequest: downRequest, cacheURL: cacheURL)
        
        return downRequest
    }
    
// MARK: - DataRequest && DownRequest Response
    private func requestResponse(_ request:WBAlBaseRequest, dataRequest dataRe:DataRequest?) {
        // 对应返回类型进行处理
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
                    if let data = response.data, let jsonString = String(data: data, encoding: .utf8) {
                        WBALog("请求失败................................................>\n Response:\(response) \n//////////////////////////////////////////////////////////////////////////\n Data:\(jsonString)")
                    }else {
                        WBALog("请求失败......................> \(response)")
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
    
    private func requestResponse(_ request:WBAlBaseRequest, downRequest downRe:DownloadRequest, cacheURL url:URL) {
        // 对应返回类型进行处理
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
    
// MARK: - MD5
    static var cacheFolder: String?
    private func formatDownloadPathWithMd5String(_ down: String, useMD5 use:Bool) -> URL {
        var md5String = use ? WBAlUtils.md5WithString(down) : down
        
        let manager = FileManager.default
        
        let cacheDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        if WBAlamofire.cacheFolder == nil {
            WBAlamofire.cacheFolder = cacheDir?.appending("/downloadCache")
        }
        
        var isDirectory: ObjCBool = true
        if !manager.fileExists(atPath: WBAlamofire.cacheFolder!, isDirectory: &isDirectory) {
            isDirectory = false
        }
        
        if !isDirectory.boolValue {
            do {
                try manager.createDirectory(atPath: WBAlamofire.cacheFolder!, withIntermediateDirectories: true, attributes: nil)
            } catch {
                WBALog("Down Failed! Create cache directory at \(WBAlamofire.cacheFolder!) is failed!")
                WBAlamofire.cacheFolder = nil
            }
        }
        
        md5String = "/" + md5String
        if let folder = WBAlamofire.cacheFolder {
            let path = folder.appending(md5String)
            return URL(fileURLWithPath: path)
        }
        
        return URL(fileURLWithPath: cacheDir!.appending(md5String))
    }
    
// MARK: - Request Record
    
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
    
// MARK: - Success && Failure
    private func requestDidFailed(_ request:WBAlBaseRequest, error requestError:Error, cacheURL url:URL? = nil, resumeData data:Data? = nil) {
        // 取消网络菊花状态
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
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
            
            // 移除request
            self.removeRecord(forRequest: request)
            request.clearCompleteClosure()
        }
    }
    
    private func requestSuccess(_ request: WBAlBaseRequest, requestResult result:Any?) {
        // 取消网络菊花状态
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        if let result = result {
            // 如果是下载，则响应返回为下载保存的路径
            if result is NSURL {
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
                    
                    if result is NSData {
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
        
        // 移除request
        DispatchQueue.main.async {
            self.removeRecord(forRequest: request)
            request.clearCompleteClosure()
        }
    }
}

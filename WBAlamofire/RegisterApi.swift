//
//  RegisterApi.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/24.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import UIKit

class RegisterApi: WBAlRequest {
    
    override var requestURL: String {
        return "/adf/2"
    }
    
    override var cacheInSeconds: TimeInterval{
        return 5 * 60
    }
    
    override var baseURL: String { return "www.baidu.com" }
}

class down: WBAlRequest {
    
    override var requestURL: String {
        return "timg?image&quality=80&size=b9999_10000&sec=1490781577869&di=e130b6d26a45afb47f42cb3c14edc2f6&imgtype=0&src=http%3A%2F%2Fpic1.win4000.com%2Fwallpaper%2F5%2F553dc1e2be070.jpg"
        
//        https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1490781577869&di=e130b6d26a45afb47f42cb3c14edc2f6&imgtype=0&src=http%3A%2F%2Fpic1.win4000.com%2Fwallpaper%2F5%2F553dc1e2be070.jpg
    }
    
    override var resumableDownloadPath: String {
        return "test.png"
    }
    
    override var responseType: WBALResponseType {
        return .data
    }
}

class login : WBAlRequest {
    
    override var baseURL: String {
//        return "http://api.qingdaikj.com/v1/"
        return "http://api.789987789.com/"
    }
    
    override var requestURL: String {
//        return "public/login"
        return "oss"
    }
    
//    override var requestMethod: HTTPMethod {
//        return .post
//    }
//    
//    override var paramEncoding: ParameterEncoding {
//        return JSONEncoding.default
//    }
    
//    override var requestParams: [String : Any]? {
//        return ["username":"15184447833", "password":"123456", "registration_id":"000000123"]
//    }
    
    override func requestCompletePreprocessor() {
        super.requestCompletePreprocessor()
        
        WBALog("request done!")
    }
}

extension login: WBAlRequestAccessoryProtocol {
    
    func requestWillStart(_ request: Any) {
        WBALog("---------------> login will start")
    }
    
    func requestWillStop(_ request: Any) {
        WBALog("---------------> login will stop")
    }
    
    func requestDidStop(_ request: Any) {
        WBALog("---------------> login did stop")
    }
}

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
        return "timg?image&quality=80&size=b9999_10000&sec=1514368052038&di=11dff689b5c73ea5f65ade4a6e442189&imgtype=0&src=http%3A%2F%2Fh.hiphotos.baidu.com%2Fimage%2Fpic%2Fitem%2F29381f30e924b899deb0d7ea64061d950b7bf650.jpg"
//        return "timg?image&quality=80&size=b9999_10000&sec=1490781577869&di=e130b6d26a45afb47f42cb3c14edc2f6&imgtype=0&src=http%3A%2F%2Fpic1.win4000.com%2Fwallpaper%2F5%2F553dc1e2be070.jpg"
    }
    
    override var resumableDownloadPath: String {
        return "sence.png"
    }
    
    override var responseType: WBALResponseType {
        return .data
    }
}

class login : WBAlRequest {
    
    override var baseURL: String {
        return "http://www.baidu.com/"
    }
    
    override var requestURL: String {
        return "userLogin"
    }
    
    override var requestMethod: WBHTTPMethod {
        return .post
    }
    
    override var paramEncoding: WBParameterEncoding {
        return .json
    }
    
    override var requestParams: [String : Any]? {
        return ["username":"15184447833", "password":"123456"]
    }
    
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

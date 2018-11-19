//
//  RegisterApi.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/24.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import UIKit

class RegisterApi: WBAlRequest {
    
    private let phone: String
    private let psd: String
    
    init(phone: String, psd: String) {
        self.phone = phone
        self.psd = psd
    }
    
    /// request url
    override var requestURL: String {
        return "/adf/2"
    }
    
    /// request params
    override var requestParams: [String : Any]? {
        return ["phone": phone, "password": psd]
    }
    
    /// request method
    override var requestMethod: WBAlHTTPMethod {
        return .post
    }
    
    /// request params encoding
    override var paramEncoding: WBAlParameterEncoding {
        return .json(encode: .default)
    }

    override func requestCompleteFilter() {
        super.requestCompleteFilter()
        // request success, you can dely response in there.
    }
    
    override func requestFailedFilter() {
        super.requestFailedFilter()
        // request failed. you can do something in there.
    }
    
    override var showLoadView: Bool {
        return true
    }
    
    override var showLoadText: String? {
        return "Register"
    }
}

class down: WBAlRequest {
    
    override var requestURL: String {
        return "timg?image&quality=80&size=b9999_10000&sec=1490781577869&di=e130b6d26a45afb47f42cb3c14edc2f6&imgtype=0&src=http%3A%2F%2Fpic1.win4000.com%2Fwallpaper%2F5%2F553dc1e2be070.jpg"
    }
    
    override var resumableDownloadPath: String {
        return "picture.png"
    }
    
    override var responseType: WBAlResponseType {
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
    
    override var requestMethod: WBAlHTTPMethod {
        return .post
    }
    
    override var paramEncoding: WBAlParameterEncoding {
        return .json(encode: .default)
    }
    
    override var requestParams: [String : Any]? {
        return ["username":"1518xxxx7833", "password":"123456"]
    }
    
    override func requestCompletePreprocessor() {
        super.requestCompletePreprocessor()
        WBAlog("request success!")
    }
    
    /// the request of validity cache Settings for 10 minutes
    override var cacheInSeconds: TimeInterval {
        return 10 * 60
    }
    
    /// open the HUD plug-in
    override var showLoadView: Bool {
        return true
    }
    /// set HUD text
    override var showLoadText: String? {
        return "Login"
    }
    /// set the HUD font
    override var showLoadTextFont: UIFont? {
        return .systemFont(ofSize: 19)
    }
    /// set the HUD textcolor
    override var showLoadTextColor: UIColor? {
        return .red
    }
    /// set the HUD animation effects
    override var showLoadAnimationType: AnimationType? {
        //  .system  use system animation
        //  .native    use a custom animation
        return .native
    }
    /// set the HUD font display position
    override var showLoadTextPosition: TextLabelPosition? {
        //  .no   don't show the words
        //  .bottom  on the bottom of the animation
        return .no
    }
}

extension login: WBAlRequestAccessoryProtocol {
    
    func requestWillStart(_ request: Any) {
        WBAlog("---------------> login: \(request) will start")
    }
    
    func requestWillStop(_ request: Any) {
        WBAlog("---------------> login: \(request) will stop")
    }
    
    func requestDidStop(_ request: Any) {
        WBAlog("---------------> login: \(request) did stop")
    }
}

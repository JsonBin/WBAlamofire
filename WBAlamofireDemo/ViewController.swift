//
//  ViewController.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/24.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let res = RegisterApi(phone: "177xxxx2467", psd: "123456")
        res.ignoreCache = true  // whether don't use cache data. Default is false.
        res.start({ (quest) in
            // you can use self here, retain cycle won't happen
            print("Success!")
            //..
        }) { (quest) in
            // you can use self here, retain cycle won't happen
            print("Failed!")
            //..
        }
        
        let test = down()
        test.start()
        
        let log = login()
        
        let chain = WBAlChainRequest()
        chain.add(log) { (chain, base) in
            // request done then..
            /*chain.add(test, callBack: nil)*/
        }
        chain.add(self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            chain.start()
        }
        
        let batch = WBAlBatchRequest(WBAlRequests: [test, log] )
        batch.add(self)
        batch.start({ (batch) in
            WBALog("success ===== \(batch)")
        }) { (batch) in
            if let request = batch.failedRequest {
                WBALog("failed  ======= \(request)")
            }
        }
        
        print(NSHomeDirectory())
        
        let s = "abcdefghijklmnopqrstuvwxyz"
        let m = String(s.suffix(s.count - 9))
        let q = String(s.prefix(5))
        // Before Swift 4.0.
        /*let m = s.substring(from: s.index(s.startIndex, offsetBy: 9))
        let q = s.substring(to: s.index(s.startIndex, offsetBy: 5))*/
        print(q)
        print(m)
        
        let t1 = telphone(address: "CD", tel: "12345678")
        let t2 = telphone(address: "HZ", tel: "0987654321")
        let u = user(name: "Lili", age: 35, tels: [t1, t2])
        if let j = u.toModel() { print(j) }
        
        let size = WBAlCache.shared.downloadCacheSize
        print(size / 1024)
        
        // custom load view
        /*let load = WBActivityIndicatorView()
        load.animationType = .native
        load.startAnimation(inView: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            load.labelPosition = .none
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            load.animationType = .system
            load.labelPosition = .bottom
        }*/
    }
}

extension ViewController :  WBAlRequestAccessoryProtocol {
    func requestWillStart(_ request: Any) {
        WBALog("====================> chain/batch will start")
    }
    
    func requestWillStop(_ request: Any) {
        WBALog("====================> chain/batch will stop")
    }
    
    func requestDidStop(_ request: Any) {
        WBALog("====================> chain/batch did stop")
    }
}


public protocol JSON {
    func toModel() -> Any?
}

extension JSON {
    
    public func toModel() -> Any? {
        let mirror = Mirror(reflecting: self)
        if mirror.children.count > 0 {
            var result: [String:Any] = [:]
            for children in mirror.children {
                let property = children.label!
                let value = children.value
                if let json = value as? JSON {
                    result[property] = json.toModel()
                }else{
                    result[property] = value
                }
            }
            return result
        }
        return self
    }
}

extension Optional : JSON {
    
    public func toModel() -> Any? {
        if let x = self {
            if let value = x as? JSON {
                return value.toModel()
            }
        }
        return nil
    }
}

extension user: JSON {}

struct user {
    var name: String
    var age: Int
    var tels: [telphone]
}

struct telphone {
    var address: String
    var tel: String
}


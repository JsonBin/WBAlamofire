# WBAlamofire
#### Encapsulate network request for the Object.

## 安装-Install
### Cocoapods

    pod 'WBAlamofire'

## 使用-Use

#### 单个请求
    class RegisterApi: WBAlRequest {
    
        override var requestURL: String {
            return "/adf/2"
        }
        
        override var cacheInSeconds: TimeInterval{
            return 5 * 60
        }
        
        override var baseURL: String { return "www.baidu.com" }
    }
    
    let res = RegisterApi()
        res.start({ (quest) in
            // 请求成功
            //..
        }) { (quest) in
            // 请求失败
            //..
    }
    
#### 串行请求
    let test = down()
    let log = login()
    let chain = WBAlChainRequest()
    chain.add(log) { (chain, base) in
        chain.add(test, callBack: nil)
    }
    chain.add(self)
    chain.start()
    
#### 并行请求
    let batch = WBAlBatchRequest(WBAlRequests: [test, log] )
    batch.add(self)
    batch.start({ (batch) in
        WBALog("success ===== \(batch)")
    }) { (batch) in
        if let request = batch.failedRequest {
            WBALog("failed  ======= \(request)")
        }
    }

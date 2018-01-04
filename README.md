WBAlamofire
==========

![License MIT](https://img.shields.io/github/license/mashape/apistatus.svg?maxAge=2592000)
![Pod version](https://img.shields.io/cocoapods/v/WBAlamofire.svg?style=flat)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform info](https://img.shields.io/cocoapods/p/WBAlamofire.svg?style=flat)](http://cocoadocs.org/docsets/WBAlamofire)
[![Build Status](https://api.travis-ci.org/JsonBin/WBAlamofire.svg?branch=master)](https://travis-ci.org/JsonBin/WBAlamofire)

## What

WBAlamofire is a high level request util based on [Alamofire][Alamofire]. It provides a High Level API for network request.

WBAlamofire is a swift version from [YTKNetwork][YTKNetwork].

## Features

* Response can be cached by expiration time
* Response can be cached by version number
* Set common base URL and CDN URL
* Validate JSON response
* Resume download
* `block` and `delegate` callback
* Batch requests (see `WBAlBatchRequest`)
* Chain requests (see `WBAlChainRequest`)
* URL filter, replace part of URL, or append common parameter 
* Plugin mechanism, handle request start and finish. A plugin for show "Loading" HUD is provided

## Installation
To use WBAlamofire add the following to your Podfile

    pod 'WBAlamofire'
    
## Requirements

| WBAlamofire Version | Alamofire Version |  Minimum iOS Target | Note |
|:------------------:|:--------------------:|:-------------------:|:-----|
| 1.x | 4.x | iOS 9 | Xcode 9+ is required. |

WBAlamofire is based on Alamofire. You can find more detail about version compability at [Alamofire README](https://github.com/Alamofire/Alamofire).

## Demo

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
    
## Thanks

Thanks for [YTKNetwork][YTKNetwork] contributors. 

## License

WBAlamofire is available under the MIT license. See the LICENSE file for more info.

<!-- external links -->

[Alamofire]:https://github.com/Alamofire/Alamofire
[YTKNetwork]:https://github.com/yuantiku/YTKNetwork

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
* `closure` and `delegate` callback
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

### YTKNetworkConfig class

We should set WBAlConfig's property at the beggining of app launching, the sample is below:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        WBAlConfig.shared.baseURL = "https://timgsa.baidu.com/"
        WBAlConfig.shared.debugLogEnable = true
        return true
    }
```

We can set the LoadView property at the beggining of app launching:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        WBAlConfig.shared.loadViewText = "Login"
        WBAlConfig.shared.loadViewTextColor = .red
        WBAlConfig.shared.loadViewAnimationType = .system
        return true
    }
```

### WBAlRequest class
```swift
class RegisterApi: WBAlRequest {

    override var requestURL: String {
        return "/adf/2"
    }

    override var cacheInSeconds: TimeInterval{
        return 5 * 60
    }

    override var baseURL: String { return "www.baidu.com" }
}
 ```
 
after, you can call request. we can use `start()` or `start(_:,failure:)` method to send request in the network request queue.
 
 ```swift
let res = RegisterApi()
res.start({ (quest) in
    // you can use self here, retain cycle won't happen
    print("Success!")
    //..
}) { (quest) in
    // you can use self here, retain cycle won't happen
    print("Failed!")
    //..
}
 ```
 
## Resumable Downloading

If you want to enable resumable downloading, you just need to overwrite the  `resumableDownloadPath` method and provide a the path you want to save the downloaded file. The file will be automatically saved to that path.

We can modify above example to support resumable downloading.

```swift
class down: WBAlRequest {
    
    override var requestURL: String {
        return "timg?image&quality=80&size=b9999_10000&sec=1490781577869&di=e130b6d26a45afb47f42cb3c14edc2f6&imgtype=0&src=http%3A%2F%2Fpic1.win4000.com%2Fwallpaper%2F5%2F553dc1e2be070.jpg"
    }
    
    override var resumableDownloadPath: String {
        return "picture.png"
    }
    
    override var responseType: WBALResponseType {
        return .data
    }
}
```

## Cache response data
 
We've implemented the `login` before, which is used for getting user information. 

We may want to cache the response. In the following example, we overwrite  the `cacheInSeconds` method, then our API will automatically cache data for specified amount of time. If the cached data is not expired, the api's `start()` and `start(_:,failure:)` will return cached data as a result directly.

```swift
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
    
    override var cacheInSeconds: TimeInterval {
        return 10 * 60
    }
    
    override var showLoadView: Bool {
        return true
    }
    
    override var showLoadText: String? {
        return "Login"
    }
}
```

The cache mechanism is transparent to the controller, which means the request caller may get the result right after invoking the request without casuing any real network traffic as long as its cached data remains valid.
    
## Thanks

Thanks for [YTKNetwork][YTKNetwork] contributors. 

## License

WBAlamofire is available under the MIT license. See the LICENSE file for more info.

<!-- external links -->

[Alamofire]:https://github.com/Alamofire/Alamofire
[YTKNetwork]:https://github.com/yuantiku/YTKNetwork

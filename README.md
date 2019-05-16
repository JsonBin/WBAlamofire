WBAlamofire
==========

[![Build Status](https://api.travis-ci.org/JsonBin/WBAlamofire.svg?branch=master)](https://travis-ci.org/JsonBin/WBAlamofire)
![Pod version](https://img.shields.io/cocoapods/v/WBAlamofire.svg?style=flat)
[![GitHub release](https://img.shields.io/github/release/JsonBin/WBAlamofire.svg)](https://shields.io/)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform info](https://img.shields.io/cocoapods/p/WBAlamofire.svg?style=flat)](http://cocoadocs.org/docsets/WBAlamofire)
[![codecov](https://codecov.io/gh/JsonBin/WBAlamofire/branch/master/graph/badge.svg)](https://codecov.io/gh/JsonBin/WBAlamofire)

<!-- ![License MIT](https://img.shields.io/github/license/mashape/apistatus.svg?maxAge=2592000) -->

## What

WBAlamofire is a high level request util based on [Alamofire][Alamofire]. It provides a High Level API for network request.

WBAlamofire is a swift version from [YTKNetwork][YTKNetwork].

[**中文说明**](Docs/README_cn.md)

## Features

* Response can be cached by expiration time
* Response can be cached by version number
* Set common base URL and CDN URL
* Validate JSON response
* Resume download
* Cache manager for response and download
* `closure` and `delegate` callback
* Batch requests (see `WBAlBatchRequest`)
* Chain requests (see `WBAlChainRequest`)
* URL filter, replace part of URL, or append common parameter 
* Plugin mechanism, handle request start and finish. A plugin for show "Loading" HUD is provided

## Installation
WBAlamofire supports multiple methods for installing the library in a project.

## CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like WBAlamofire in your projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.2.0+ is required to build WBAlamofire.

#### Podfile

To integrate WBAlamofire into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'

target 'TargetName' do
use_frameworks!

pod 'WBAlamofire'

end
```
-
with swift 4.0/4.2 used in cocoapods:
```ruby
pod 'WBAlamofire', '1.2.1'
```
    
Then, run the following command:

```bash
$ pod install
```

## Carthage


[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate WBAlamofire into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "JsonBin/WBAlamofire"
```

Run `carthage` to build the framework and drag the built `WBAlamofire.framework` into your Xcode project.

## Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the swift compiler. It is in early development, but WBAlamofire does not support its use on supported platforms.

Once you have your Swift package set up, adding WBAlamofire as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```bash
dependencies: [
    .package(url: "https://github.com/JsonBin/WBAlamofire.git", from: "2.0.0")
]
```
    
## Requirements

- iOS 10.0+ / macOS 10.12+ / tvOS 10.0+ / watchOS 3.0+
- Xcode 10.2+
- Swift 5.0+

| WBAlamofire Version | Alamofire Version |  Minimum iOS Target |  Minimum macOS Target  | Minimum watchOS Target  | Minimum tvOS Target  |                Note                 |
|:------------------:|:--------------------:|:-------------------:|:----------------------------:|:----------------------------:|:----------------------------:|:--------------------------------------------------------|
| 1.x | 4.x | iOS 8 | OS X 10.10 | watchOS 2.0 | tvOS 9.0 | Xcode 9+ is required. |
| 2.x | 5.x | iOS 10 | OS X 10.12 | watchOS 3.0 | tvOS 10.0 | Xcode 10.2+ is required. |

WBAlamofire is based on Alamofire. You can find more detail about version compability at [Alamofire README](https://github.com/Alamofire/Alamofire).

## Demo

### WBAlConfig class

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
}
 ```
 
after, you can call request. we can use `start()` or `start(_:,failure:)` method to send request in the network request queue.
 
 ```swift
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
 ```
 
### WBActivityIndicatorView class

WBAlamofire has a set of plug-ins support iOS system use only. It can be displayed when a network request to a default "Loading" style of the HUD. the plug-in with two forms of animation effects, one is system, another for custom animation. This plugin is the default in a disabled state, if want to use the plug-in, can refer to the following sample set:

For each request set up separately:

```swift
class login : WBAlRequest {
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
        //  .native  use a custom animation
        return .native
    }
    /// set the HUD font display position
    override var showLoadTextPosition: TextLabelPosition? {
        //  .no   don't show the words
        //  .bottom  on the bottom of the animation
        return .no
    }
}
```

In the APP starts unified set:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    WBAlConfig.shared.loadViewText = "Login"
    WBAlConfig.shared.loadViewTextFont = .systemFont(ofSize: 16)
    WBAlConfig.shared.loadViewTextColor = .red
    WBAlConfig.shared.loadViewAnimationType = .system
    WBAlConfig.shared.loadViewTextPosition = .bottom
}
```

When make unified set, however, need to separate Settings for each request, make the HUD plug-in in the available state:

```swift
class login : WBAlRequest {
    /// open the HUD plug-in
    override var showLoadView: Bool {
        return true
    }
}
```

### WBAlCache class

WBAlamofire provides a mechanism of cache handling. A set with the result of the request and download data processing of apis, include statistics, remove, and other functions.

```swift
// all the download cache file size
WBAlCache.shared.downloadCacheSize
// all requests the cache file size
WBAlCache.shared.responseCacheFilesSize
// remove single download file
WBAlCache.shared.removeDownloadFiles(with: `YourFileName`)
// remove all requests results cache file
WBAlCache.shared.removeCacheFiles()
// remove all the downloaded file
WBAlCache.shared.removeDownloadFiles()
// remove all download cache and network request results
WBAlCache.shared.removeAllFiles()
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
    
    override var responseType: WBAlResponseType {
        return .data
    }
}
```

## Upload

You can easily upload data to the server using only 4-5 lines of code:

```swift
    class upload: WBAlRequest {

    private let data: Data?

    init(data: Data?) {
        self.data = data
    }

    override var requestURL: String {
        return "v2/upload/album"
    }

    override var requestMethod: WBAlHTTPMethod {
        return .post
    }

    // TODO: Upload data to server, implement any of the following three methods

    override var requestDataClosure: WBAlRequest.WBAlMutableDataClosure? {
        if let data = self.data {
            return { mutlidata in
                mutlidata.append(data, withName: "file", mimeType: "image/jpg")
            }
        }
        return nil
    }

    override var uploadData: Data? {
        return data
    }

    override var uploadFile: URL? {
        return URL(fileURLWithPath: "xxxx")
    }
}
```
You only need to implement `requestDataClosure`/`uploadData`/`uploadFile`any of the three methods for uploading files.

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
    
    override var requestMethod: WBAlHTTPMethod {
        return .post
    }
    
    override var paramEncoding: WBAlParameterEncoding {
        return .json(encode: .default)
    }
    
    override var requestParams: [String : Any]? {
        return ["username":"151xxxx7833", "password":"123456"]
    }
    
    override func requestCompletePreprocessor() {
        super.requestCompletePreprocessor()
        WBAlog("request done!")
    }
    
    /// the request of validity cache Settings for 10 minutes
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

Thanks for [YTKNetwork][YTKNetwork] and [Alamofire][Alamofire] contributors. 

See more information with [YTKNetwork][YTKNetwork].

## License

WBAlamofire is available under the [MIT license](https://raw.github.com/rs/SDWebImage/master/LICENSE). See the LICENSE file for more info.

<!-- external links -->

[Alamofire]:https://github.com/Alamofire/Alamofire
[YTKNetwork]:https://github.com/yuantiku/YTKNetwork

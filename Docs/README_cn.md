WBAlamofire
==========

[![Build Status](https://api.travis-ci.org/JsonBin/WBAlamofire.svg?branch=master)](https://travis-ci.org/JsonBin/WBAlamofire)
![Pod version](https://img.shields.io/cocoapods/v/WBAlamofire.svg?style=flat)
[![GitHub release](https://img.shields.io/github/release/JsonBin/WBAlamofire.svg)](https://shields.io/)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform info](https://img.shields.io/cocoapods/p/WBAlamofire.svg?style=flat)](http://cocoadocs.org/docsets/WBAlamofire)
[![codecov](https://codecov.io/gh/JsonBin/WBAlamofire/branch/master/graph/badge.svg)](https://codecov.io/gh/JsonBin/WBAlamofire)

<!-- ![License MIT](https://img.shields.io/github/license/mashape/apistatus.svg?maxAge=2592000) -->

## 是什么？

WBAlamofire是一个基于[Alamofire][Alamofire]的网络请求框架。它提供了一组高性能的网络请求API.

WBAlamofire当前为[YTKNetwork][YTKNetwork]的Swift版本.

## 提供的功能

* 支持按缓存时间来缓存请求结果
* 支持按版本号来缓存请求结果
* 支持设置统一可替换的URL和CDN URL
* 支持设置请求的返回类型
* 支持断点下载功能
* 支持缓存管理类，可处理请求结果和下载数据
* 使用`closure` 和 `delegate`回调结果
* 提供批量的网络请求(具体查看 `WBAlBatchRequest`)
* 提供具有相互依赖关系的网络请求(具体查看 `WBAlChainRequest`)
* 支持网络请求 URL 的 filter，可以统一为网络请求加上一些参数，或者修改一些路径
* 支持对缓存的处理方法，统计及删除缓存结果(详情查看 `WBAlCache`)
* 为iOS提供了一套插件机制，可快速的为请求设置HUD，可在网络请求过程中显示 "Loading" 样式的HUD

## 安装
WBAlamofire支持多种安装方法.

## CocoaPods

若还未安装[Cocoapods](https://cocoapods.org/)，请先通过以下的命令先安装CocoaPods:

```bash
$ gem install cocoapods
```

> WBAlamofire安装需要使用 CocoaPods 1.2.0+ 版本以上.

#### Podfile

将以下代码添加到你的`Podfile`文件中:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'

target 'TargetName' do
pod 'WBAlamofire'
end
```
-
在swift4.0/4.2版本中使用以下pod:
```ruby
pod 'WBAlamofire', '1.2.1'
```

之后，使用以下命令运行安装命令:

```bash
$ pod install
```

## Carthage

[Carthage](https://github.com/Carthage/Carthage)是一个分散的三方管理框架, 可编译你的依赖包并给你提供一个frameworks文件.

你可以运行以下命令来使用[Homebrew](http://brew.sh/)安装Carthage:

```bash
$ brew update
$ brew install carthage
```

你如果想使用Carthage来将WBAlamofire导入到你的项目中, 将以下代码放入到你的`Cartfile`文件中:

```ogdl
github "JsonBin/WBAlamofire"
```

运行`carthage update`并将生成的`WBAlamofire.framework`导入到你的项目中.

## SPM包管理器

[SPM](https://swift.org/package-manager/)是一个自动化的快速集成和编译代码的工具. 在早期的版本中，WBAlamofire并不支持在支持的平台上使用.

一旦你想使用SPM管理你的项目, 只需要将WBAlamofire添加为依赖包即可. 在`Package.swift`的`dependencies`添加如下代码即可使用:

```bash
dependencies: [
    .package(url: "https://github.com/JsonBin/WBAlamofire.git", from: "2.0.0")
]
```
    
## 安装要求

- iOS 10.0+ / macOS 10.12+ / tvOS 10.0+ / watchOS 3.0+
- Xcode 10.2+
- Swift 5.0+

| WBAlamofire Version | Alamofire Version |  Minimum iOS Target |  Minimum macOS Target  | Minimum watchOS Target  | Minimum tvOS Target  |                Note                 |
|:------------------:|:--------------------:|:-------------------:|:----------------------------:|:----------------------------:|:----------------------------:|:--------------------------------------------------------|
| 1.x | 4.x | iOS 8 | OS X 10.10 | watchOS 2.0 | tvOS 9.0 | Xcode 9+ is required. |
| 2.x | 5.x | iOS 10 | OS X 10.12 | watchOS 3.0 | tvOS 10.0 | Xcode 10.2+ is required. |

WBAlamofire基于Alamofire的网络框架. 你可以在[Alamofire README](https://github.com/Alamofire/Alamofire)查看更多的细节.

## 使用

### WBAlConfig类

你可以在APP启动的时候设置`WBAlConfig`的参数，例如以下:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    WBAlConfig.shared.baseURL = "https://timgsa.baidu.com/"
    WBAlConfig.shared.debugLogEnable = true
    return true
}
```

同样的，你可以在APP启动的时候统一设置加载框的参数数据:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    WBAlConfig.shared.loadViewText = "Login"
    WBAlConfig.shared.loadViewTextColor = .red
    WBAlConfig.shared.loadViewAnimationType = .system
    return true
}
```

### WBAlRequest类

```swift
class RegisterApi: WBAlRequest {
    
    private let phone: String
    private let psd: String
    
    init(phone: String, psd: String) {
        self.phone = phone
        self.psd = psd
    }
    
    /// 网络请求地址
    override var requestURL: String {
        return "/adf/2"
    }
    
    /// 网络请求参数
    override var requestParams: [String : Any]? {
        return ["phone": phone, "password": psd]
    }
    
    /// 网络请求方式
    override var requestMethod: WBAlHTTPMethod {
        return .post
    }
    
    /// 网络请求参数编码方式
    override var paramEncoding: WBAlParameterEncoding {
        return .json(encode: .default)
    }
    
    override func requestCompleteFilter() {
        super.requestCompleteFilter()
        // 请求成功后执行，可在这里处理请求结果数据
    }
    
    override func requestFailedFilter() {
        super.requestFailedFilter()
        // 请求失败住线程执行，可在这里处理请求失败之后逻辑
    }
}
 ```

初始化完成之后，可以调用`start()` 或者 `start(_:,failure:)`方法在网络请求队列中发起网络请求:
 
 ```swift
let res = RegisterApi(phone: "1xxxxxxxxxxxx7", psd: "123456")
res.ignoreCache = true  // 是否不使用缓存，默认使用
res.start({ (quest) in
    // 你可以直接在这里使用self，不会造成循环引用
    print("Success!")
    //..
}) { (quest) in
    // 你可以直接在这里使用self，不会造成循环引用
    print("Failed!")
    //..
}
 ```
 
### WBActivityIndicatorView类

WBAlamofire自带的一套插件仅支持iOS系统使用. 可在发起网络请求的时候显示一个默认 "Loading" 样式的HUD，该插件带有两种形式的动画效果，一种为系统，另一种为自定义动画. 此插件默认是处于禁用状态，若想使用该插件，可参照以下示例设置:

对每一个request单独设置:

```swift
class login : WBAlRequest {
    /// 开启HUD插件
    override var showLoadView: Bool {
        return true
    }
    /// 设置HUD文字
    override var showLoadText: String? {
        return "Login"
    }
    /// 设置HUD字体
    override var showLoadTextFont: UIFont? {
        return .systemFont(ofSize: 19)
    }
    /// 设置HUD字体颜色
    override var showLoadTextColor: UIColor? {
        return .red
    }
    /// 设置HUD动画效果
    override var showLoadAnimationType: AnimationType? {
        //  .system  采用系统动画, 即菊花
        //  .native  采用自定义动画
        return .native
    }
    /// 设置HUD字体显示位置
    override var showLoadTextPosition: TextLabelPosition? {
        //  .no   不显示文字
        //  .bottom  文字放于动画底部
        return .no
    }
}
```

在APP启动时统一设置:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    WBAlConfig.shared.loadViewText = "Login"
    WBAlConfig.shared.loadViewTextFont = .systemFont(ofSize: 16)
    WBAlConfig.shared.loadViewTextColor = .red
    WBAlConfig.shared.loadViewAnimationType = .system
    WBAlConfig.shared.loadViewTextPosition = .bottom
}
```

但是，在进行统一设置的时候，需要对每一个request进行单独的设置，使HUD插件处于可用状态:

```swift
class login : WBAlRequest {
    /// 开启HUD插件
    override var showLoadView: Bool {
        return true
    }
}
```

### WBAlCache缓存管理

WBAlamofire提供了一套对缓存处理的机制. 有一套对请求结果和下载数据进行处理的API，包含统计、移除等功能.

```swift
// 所有的下载缓存文件大小
WBAlCache.shared.downloadCacheSize
// 所有的请求结果缓存文件大小
WBAlCache.shared.responseCacheFilesSize
// 对单个的下载文件删除
WBAlCache.shared.removeDownloadFiles(with: `YourFileName`)
// 移除所有的请求结果缓存文件
WBAlCache.shared.removeCacheFiles()
// 移除所有的下载文件
WBAlCache.shared.removeDownloadFiles()
// 移除所有的下载和网络请求结果缓存
WBAlCache.shared.removeAllFiles()
```
 
## 断点下载

如果你想使用断点下载功能，你只需要重写`resumableDownloadPath`参数(并且不返回空)提供一个你想要保存的文件的名字. 下载的文件会自动保存到你设置文件名中.

断点下载不支持使用缓存. 以下为支持断点下载功能的简单示例:

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

## 文件上传

提供了便捷的文件上传管理，只需要4-5行代码即可将文件上传到服务端:

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
上传文件的时候只需要实现`requestDataClosure`/`uploadData`/`uploadFile`三种之中的任何一个方法即可。


## 缓存数据

以下为`login`的简单示例，它是使用来获取用户的数据信息.

同样，你也可以选择缓存返回的数据(即用户个人数据). 在下面的示例中，重新了`cacheInSeconds`方法，在获取到数据之后，API会自动缓存数据到本地直到超出了缓存的时间. 如果缓存的数据没有超过限定的时间，那么当请求数据调用`start()` 或者 `start(_:,failure:)`会优先返回本地缓存的数据.

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
        return ["username":"15184447833", "password":"123456"]
    }
    
    override func requestCompletePreprocessor() {
        super.requestCompletePreprocessor()
        WBAlog("request done!")
    }
    
    /// 对请求结果设置10分钟的缓存有效期
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

网络缓存机制相对应控制器是可用的. 它意味着只要在缓存数据有效的范围内，用户调用网络请求是没有产生任何流量的.
    
## 感谢

十分感谢 [YTKNetwork][YTKNetwork]和[Alamofire][Alamofire]的作者.

查看更多的信息请访问[YTKNetwork][YTKNetwork]

## 开源许可

WBAlamofire遵循[MIT license](https://raw.github.com/rs/SDWebImage/master/LICENSE)开源许可. 在LICENSE file查看更多的信息

<!-- external links -->

[Alamofire]:https://github.com/Alamofire/Alamofire
[YTKNetwork]:https://github.com/yuantiku/YTKNetwork

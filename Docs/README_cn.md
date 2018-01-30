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
platform :ios, '8.0'

target 'TargetName' do
pod 'WBAlamofire'
end
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
    
## 安装要求

- iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 9.1+
- Swift 4.0+

| WBAlamofire Version | Alamofire Version |  Minimum iOS Target |  Minimum macOS Target  | Minimum watchOS Target  | Minimum tvOS Target  |                Note                 |
|:------------------:|:--------------------:|:-------------------:|:----------------------------:|:----------------------------:|:----------------------------:|:--------------------------------------------------------|
| 1.x | 4.x | iOS 8 | OS X 10.10 | watchOS 2.0 | tvOS 9.0 | Xcode 9+ is required. |

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

    override var requestURL: String {
        return "/adf/2"
    }

    override var cacheInSeconds: TimeInterval{
        return 5 * 60
    }

    override var baseURL: String { return "www.baidu.com" }
}
 ```

初始化完成之后，可以调用`start()` 或者 `start(_:,failure:)`方法在网络请求队列中发起网络请求:
 
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

 
## 断点下载

如果你想使用断点下载功能，你只需要重写`resumableDownloadPath`参数(并且不返回空)提供一个你想要保存的文件的名字. 下载的文件会自动保存到你设置文件名中.

以下为支持断点下载功能的简单示例:

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

网络缓存机制相对应控制器是可用的. 它意味着只要在缓存数据有效的范围内，用户调用网络请求是没有产生任何流量的.
    
## 感谢

十分感谢 [YTKNetwork][YTKNetwork]的作者.

查看更多的信息请访问[YTKNetwork][YTKNetwork]

## 开源许可

WBAlamofire遵循[MIT license](https://raw.github.com/rs/SDWebImage/master/LICENSE)开源许可. 在LICENSE file查看更多的信息

<!-- external links -->

[Alamofire]:https://github.com/Alamofire/Alamofire
[YTKNetwork]:https://github.com/yuantiku/YTKNetwork

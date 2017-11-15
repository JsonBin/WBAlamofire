# WBAlamofire
#### Encapsulate network request for the Object.

## 安装-Install
### Cocoapods

    pod 'WBAlamofire'

### 描述-Descriptions
#### BaseRequest

    /// 上传数据时的closure
    typealias WBAlMutableDataClosure = (_ data: MultipartFormData) -> Void
    
    typealias WBAlRequestCompleteClosure = (_ request: WBAlBaseRequest) -> Void
    
    /// 需要更改baseURL时调用
    var baseURL: String { get }
    
    /// 每一个model请求的url
    var requestURL: String { get }
    
    /// 需要使用cdnURL时调用
    var cdnURL: String { get }
    
    /// 请求的method
    var requestMethod: WBHTTPMethod { get }
    
    /// 需要添加的请求头
    var requestHeaders: HTTPHeaders? { get }
    
    /// 需要添加的请求参数
    var requestParams: [String: Any]? { get }
    
    /// 请求时param编码
    var paramEncoding: WBParameterEncoding { get }
    
    /// 请求返回的数据类型
    var responseType: WBALResponseType { get }
    
    /// 请求的优先权
    var priority: WBALRequestPriority? { get }
    
    // 上传文件时以下面三种任选一种作为上传数据依据
    /// 上传文件时上传的数据
    var requestDataClosure: WBAlMutableDataClosure? { get }
    
    /// 上传文件时文件的url
    var uploadFile: URL? { get }
    
    /// 上传文件时文件的data
    var uploadData: Data? { get }
    
    /// 下载文件保存的名字，默认存放在 .../Documents/downloadCache/...下
    var resumableDownloadPath: String { get }
    
    /// https时使用的证书的用户名以及密码, first is user, last is password.
    var requestAuthHeaders: [String]? { get }
    
    /// 是否使用cdn
    var useCDN: Bool { get }
    
    /// 响应状态码
    var statusCode: Int { get }
    

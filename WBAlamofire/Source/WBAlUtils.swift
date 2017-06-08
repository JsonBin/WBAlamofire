//
//  WBAlUtils.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/27.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

import Foundation

/// 私有调用类
open class WBAlUtils {

    // md5加密算法
    open class func md5WithString(_ string: String) -> String {
        let str = string.cString(using: .utf8)
        let strLen = CUnsignedInt(string.lengthOfBytes(using: .utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        var hash : String = ""
        for i in 0 ..< digestLen {
            hash = hash.appendingFormat("%02x", result[i])
        }
        result.deinitialize()
        return hash
    }
    
    /// app 版本号
    open class func appVersion() -> String? {
        if let dictionary = Bundle.main.infoDictionary, let version = dictionary["CFBundleShortVersionString"] as? String {
            return version
        }
        return nil
    }
    
    // set backup
    open class func addNotBackupAttribute(_ path:String) -> Void {
        var url = URL(fileURLWithPath: path)
        var backup = URLResourceValues()
        backup.isExcludedFromBackup = true
        do {
            try url.setResourceValues(backup)
        } catch let error {
            WBALog("error to set do not backup attribute, reason: \"\(error.localizedDescription)\'")
        }
    }
    
    // from request encoding
    open class func stringEncodingFromRequest(_ request:WBAlBaseRequest) -> String.Encoding {
        var stringEncoding = String.Encoding.utf8
        if let textEncoding = request.request?.response?.textEncodingName {
            let encoding = CFStringConvertIANACharSetNameToEncoding(textEncoding as CFString)
            if encoding != kCFStringEncodingInvalidId {
                stringEncoding = String.Encoding(rawValue: UInt(encoding))
            }
        }
        return stringEncoding
    }
    
    open class func validataResumeData(_ data:Data) -> Bool {
        // From http://stackoverflow.com/a/22137510/3562486
        if data.count < 1 { return false }
        let resumeDic: Dictionary<String, Any>
        do {
            resumeDic = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as! Dictionary<String, Any>
        } catch {
            return false
        }
        
        if resumeDic.isEmpty { return false }
        
        // Before iOS 9 & Mac OS X 10.11
        if #available(iOS 9.0, *) { }else{
            let localPath = resumeDic["NSURLSessionResumeInfoLocalPath"] as! String
            if localPath.isEmpty { return false}
            return FileManager.default.fileExists(atPath: localPath)
        }
        // After iOS 9 we can not actually detects if the cache file exists. This plist file has a somehow
        // complicated structue. Besides, the plist structure is different between iOS 9 and iOS 10.
        // We can only assume that the plist being successfully parsed means the resume data is valid.
        return true
    }
}

/// NSKeyedArchiver metadata
open class WBAlMetadata: NSObject, NSSecureCoding {
    
    /// 缓存版本号
    open var version: Int?
    
    /// 设置的刷新标志
    open var sensitiveDataString: String?
    
    /// string编码
    open var stringEncoding: String.Encoding?
    
    /// 创建时间
    open var createDate: Date?
    
    /// app版本号
    open var appVersionString: String?
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    override init() { }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        
        self.version = aDecoder.decodeObject(forKey: "version") as? Int
        self.sensitiveDataString = aDecoder.decodeObject(forKey: "sensitiveDataString") as? String
        if let encode = aDecoder.decodeObject(forKey: "stringEncoding") as? UInt {
            self.stringEncoding = String.Encoding(rawValue: encode)
        }
        self.createDate = aDecoder.decodeObject(forKey: "createDate") as? Date
        self.appVersionString = aDecoder.decodeObject(forKey: "appVersionString") as? String
    }
    
    public func encode(with aCoder: NSCoder) {
        
        aCoder.encode(self.version, forKey: "version")
        aCoder.encode(self.sensitiveDataString, forKey: "sensitiveDataString")
        aCoder.encode(self.stringEncoding?.rawValue, forKey: "stringEncoding")
        aCoder.encode(self.createDate, forKey: "createDate")
        aCoder.encode(self.appVersionString, forKey: "appVersionString")
    }
}

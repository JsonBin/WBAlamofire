//
//  WBAlUtils.swift
//  WBAlamofire
//
//  Created by zwb on 17/3/27.
//  Copyright © 2017年 HengSu Technology. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Foundation
#endif

public final class WBAlUtils {

    /// Md5 encryption algorithm. And reference to Kingfisher algorithm
    public class func md5WithString(_ string: String) -> String {
        return string.wbal.md5
        // the system method
        /*let str = string.cString(using: .utf8)
        let strLen = CUnsignedInt(string.lengthOfBytes(using: .utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        var hash : String = ""
        for i in 0 ..< digestLen {
            hash = hash.appendingFormat("%02x", result[i])
        }
        result.deallocate(capacity: digestLen)
        result.deinitialize()
        return hash*/
    }
    
    /// app version
    public class var appVersion: String? {
        if let dictionary = Bundle.main.infoDictionary,
            let version = dictionary["CFBundleShortVersionString"] as? String {
            return version
        }
        return nil
    }
    
    // set backup(disable up automatic backup for iCloud)
    public class func addNotBackupAttribute(_ path: String) -> Void {
        var url = URL(fileURLWithPath: path)
        var backup = URLResourceValues()
        backup.isExcludedFromBackup = true
        do {
            try url.setResourceValues(backup)
        } catch let error {
            WBAlog("error to set do not backup attribute, reason: \"\(error)\'")
        }
    }
    
    // from request encoding
    public class func stringEncodingFromRequest(_ request: WBAlBaseRequest) -> String.Encoding {
        var stringEncoding = String.Encoding.utf8
        if let textEncoding = request.request?.response?.textEncodingName {
            let encoding = CFStringConvertIANACharSetNameToEncoding(textEncoding as CFString)
            if encoding != kCFStringEncodingInvalidId {
                stringEncoding = String.Encoding(rawValue: UInt(encoding))
            }
        }
        return stringEncoding
    }
    
    public class func validataResumeData(_ data: Data? ) -> Bool {
        // From http://stackoverflow.com/a/22137510/3562486
        guard let data = data else { return false }
        if data.count < 1 { return false }
        let resumeDic: Dictionary<String, Any>?
        do {
            resumeDic = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? Dictionary<String, Any>
        } catch {
            return false
        }

        guard let resume = resumeDic else { return false }
        
        if resume.isEmpty { return false }
        
        // Before iOS 9 & Mac OS X 10.11
        if #available(iOS 9.0, *) { }else{
            let localPath = resume["NSURLSessionResumeInfoLocalPath"] as? String
            guard let path = localPath, !path.isEmpty else { return false}
            return FileManager.default.fileExists(atPath: path)
        }
        // After iOS 9 we can not actually detects if the cache file exists. This plist file has a somehow
        // complicated structue. Besides, the plist structure is different between iOS 9 and iOS 10.
        // We can only assume that the plist being successfully parsed means the resume data is valid.
        return true
    }
    
#if os(iOS)
    /// Get the top current viewController.
    public class var wb_getCurrentViewController: UIViewController? {
        var result: UIViewController?
        var window = UIApplication.shared.keyWindow
        #if swift(>=4.2)
        if window?.windowLevel != .normal {
            let windows = UIApplication.shared.windows
            for win in windows {
                if win.windowLevel == .normal {
                    window = win
                    break
                }
            }
        }
        #else
        if window?.windowLevel != UIWindowLevelNormal {
            let windows = UIApplication.shared.windows
            for win in windows {
                if win.windowLevel == UIWindowLevelNormal {
                    window = win
                    break
                }
            }
        }
        #endif
        let forntView = window?.subviews.first
        let responder = forntView?.next
        if responder is UIViewController {
            result = responder as? UIViewController
        }else{
            result = window?.rootViewController
        }
        return result
    }
#endif
}

/// NSKeyedArchiver metadata
public final class WBAlMetadata: NSObject, NSSecureCoding {
    
    /// Cached version number
    public var version: Int?
    
    /// Set the refresh data
    public var sensitiveDataString: String?
    
    /// string encoding
    public var stringEncoding: String.Encoding?
    
    /// create date
    public var createDate: Date?
    
    /// app version
    public var appVersionString: String?
    
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

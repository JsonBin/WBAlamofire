//
//  WBAlEnums.swift
//  WBAlamofire
//
//  Created by uneed-zwb on 2018/11/19.
//  Copyright © 2018 HengSu Technology. All rights reserved.
//

import Foundation
import Alamofire

/// the request priority
/// 网络请求优先级别
///
/// - `default`: the default
/// - low: the lower
/// - high: the highest
public enum WBAlRequestPriority: Int8 {
    case `default` = 0
    case low = -4
    case high = 4
}

/// the request returns the data type
/// 网络请求返回类型
///
/// - `default`: default is Data
/// - json: JSON
/// - string: String
/// - data: Data
/// - plist: Plist
public enum WBAlResponseType: Int8 {
    case `default`, json, string, data, plist
}

/// the request need to call the method
/// 网络请求方式
///
/// - options: "OPTIONS"
/// - get: "GET"
/// - head: "HEAD"
/// - post: "POST"
/// - put: "PUT"
/// - patch: "PATCH"
/// - delete: "DELETE"
/// - trace: "TRACE"
/// - connect: "CONNECT"
public enum WBAlHTTPMethod {
    case options, get, head, post, put, patch, delete, trace, connect

    public init(rawValue: HTTPMethod) {
        switch rawValue {
        case .options:  self = .options
        case .get:      self = .get
        case .head:     self = .head
        case .post:     self = .post
        case .put:      self = .put
        case .patch:    self = .patch
        case .delete:   self = .delete
        case .trace:    self = .trace
        case .connect:  self = .connect
        }
    }

    public var rawValue: HTTPMethod {
        switch self {
        case .options: return .options
        case .get:     return .get
        case .head:    return .head
        case .post:    return .post
        case .put:     return .put
        case .patch:   return .patch
        case .delete:  return .delete
        case .trace:   return .trace
        case .connect: return .connect
        }
    }
}

/// parameter encoding
/// 网络请求参数编码方式
///
/// - json: JSONEncoding
/// - url: URLEncoding
/// - plist: PropertyListEncoding
public enum WBAlParameterEncoding {

    /// The json encoding.
    ///
    /// - `default`: JSONEncoding.default
    /// - prettyPrinted: JSONEncoding.prettyPrinted
    public enum JSON {
        case `default`, prettyPrinted
    }

    /// The url encoding.
    ///
    /// - `default`: URLEncoding.default
    /// - methodDependent: URLEncoding.methodDependent
    /// - queryString: URLEncoding.queryString
    /// - httpBody: URLEncoding.httpBody
    public enum URL {
        case `default`, methodDependent, queryString, httpBody
    }

    /// The plist encoding.
    ///
    /// - `default`: PropertyListEncoding.default
    /// - xml: PropertyListEncoding.xml
    /// - binary: PropertyListEncoding.binary
    public enum PList {
        case `default`, xml, binary
    }

    case json(encode: JSON)
    case url(encode: URL)
    case plist(encode: PList)

    public init(rawValue: ParameterEncoding) {
        switch rawValue {
        case is JSONEncoding:
            self = .json(encode: .default)
        case is URLEncoding:
            self = .url(encode: .default)
        case is PropertyListEncoding:
            self = .plist(encode: .default)
        default: self = .url(encode: .default)
        }
    }

    public var rawValue: ParameterEncoding {
        switch self {
        case .json(let encode):     return encode.encoding
        case .url(let encode):      return encode.encoding
        case .plist(let encode):    return encode.encoding
        }
    }
}

extension WBAlParameterEncoding.JSON {
    public var encoding: ParameterEncoding {
        switch self {
        case .default:
            return JSONEncoding.default
        case .prettyPrinted:
            return JSONEncoding.prettyPrinted
        }
    }
}

extension WBAlParameterEncoding.URL {
    public var encoding: ParameterEncoding {
        switch self {
        case .default:
            return URLEncoding.default
        case .methodDependent:
            return URLEncoding.methodDependent
        case .queryString:
            return URLEncoding.queryString
        case .httpBody:
            return URLEncoding.httpBody
        }
    }
}

extension WBAlParameterEncoding.PList {
    public var encoding: ParameterEncoding {
        switch self {
        case .default:
            return PropertyListEncoding.default
        case .xml:
            return PropertyListEncoding.xml
        case .binary:
            return PropertyListEncoding.binary
        }
    }
}

extension WBAlParameterEncoding {
    public var urlEncoding: Bool {
        if case .url(_) = self {
            return true
        }
        return false
    }

    public var jsonEncoding: Bool {
        if case .json(_) = self {
            return true
        }
        return false
    }

    public var plistEncoding: Bool {
        if case .plist(_) = self {
            return true
        }
        return false
    }
}

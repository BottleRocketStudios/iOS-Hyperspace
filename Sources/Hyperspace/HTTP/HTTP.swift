//
//  HTTP.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

//
//  TODO: Future functionality:
//          - Consider converting HTTP.Status to a "RawRepresentable" type with static constants for codes. This would allow clients to extend or provide their own status codes and eliminate the need for an 'unknown' enum case.
//          - Are there any HTTP.HeaderKeys that we should add (or remove)?
//          - Are there any HTTP.HeaderValues that we should add (or remove)?
//

import Foundation

// swiftlint:disable nesting
/// Represents common components encountered when dealing with HTTP.
public struct HTTP {
    
    /// Represents the HTTP method used to execute a network request.
    public enum Method: String {
        case get = "GET"
        case head = "HEAD"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }
    
    /// Represents the key portion of a HTTP header field key-value pair.
    public struct HeaderKey: RawRepresentable {
        public var rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
    
    /// Represents the value portion of a HTTP header field key-value pair.
    public struct HeaderValue: RawRepresentable {
        public var rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
    
    /// Represents a HTTP status code.

    public enum Status {
        public enum Success: Int {
            case unknown = -1
            case ok = 200
            case created = 201
            case accepted = 202
            case nonAuthoritativeInformation = 203
            case noContent = 204
            case resetContent = 205
            case partialContent = 206
            case multiStatus = 207
            case alreadyReported = 208
            case imUsed = 226
        }
        
        public enum Redirection: Int {
            case unknown = -1
            case multipleChoices = 300
            case movedPermanently = 301
            case found = 302
            case seeOther = 303
            case notModified = 304
            case useProxy = 305
            case switchProxy = 306
            case temporaryRedirect = 307
            case permanentRedirect = 308
        }
        
        public enum ClientError: Int {
            case unknown = -1
            case badRequest = 400
            case unauthorized = 401
            case paymentRequired = 402
            case forbidden = 403
            case notFound = 404
            case methodNotAllowed = 405
            case notAcceptable = 406
            case proxyAuthenticationRequired = 407
            case requestTimeout = 408
            case conflict = 409
            case gone = 410
            case lengthRequried = 411
            case preconditionFailed = 412
            case payloadTooLarge = 413
            case uriTooLong = 414
            case unsupportedMediaType = 415
            case rangeNotSatisfiable = 416
            case expectationFailed = 417
            case imATeapot = 418
            case misdirectedRequest = 421
            case unproccessableEntity = 422
            case locked = 423
            case failedDependency = 424
            case upgradeRequired = 426
            case preconditionRequired = 428
            case tooManyRequests = 429
            case requestHeaderFieldsTooLarge = 431
            case unavailableForLegalReasons = 451
        }
        
        public enum ServerError: Int {
            case unknown = -1
            case internalServerError = 500
            case notImplemented = 501
            case badGateway = 502
            case serviceUnavailable = 503
            case gatewayTimeout = 504
            case httpVersionNotSupported = 505
            case variantAlsoNegotiates = 506
            case insufficientStorage = 507
            case loopDetected = 508
            case notExtended = 510
            case networkAuthenticationRequired = 511
        }
        
        case unknown(Int)
        case success(Success)
        case redirection(Redirection)
        case clientError(ClientError)
        case serverError(ServerError)
        
        init(code: Int) {
            switch code {
            case 200..<300:
                self = .success(Success(rawValue: code) ?? .unknown)
            case 300..<400:
                self = .redirection(Redirection(rawValue: code) ?? .unknown)
            case 400..<500:
                self = .clientError(ClientError(rawValue: code) ?? .unknown)
            case 500..<600:
                self = .serverError(ServerError(rawValue: code) ?? .unknown)
            default:
                self = .unknown(code)
            }
        }
    }
    
    /// Represents a HTTP response.
    public struct Response {
        
        /// The raw HTTP status code for this response.
        public let code: Int
        
        /// The raw Data associated with the HTTP response, if any data was provided.
        public let data: Data?
        
        /// The parsed HTTP status associated with this response.
        public var status: HTTP.Status {
            return HTTP.Status(code: code)
        }
        
        /// A convenience property to encode the data associated with this response into a String. Can be useful for debugging.
        public var dataString: String? {
            return data.flatMap { String(data: $0, encoding: .utf8) }
        }
        
        /// Initialize a new HTTP.Response with any given HTTP status code and Data.
        ///
        /// - Parameters:
        ///   - code: The raw HTTP status code for this response.
        ///   - data: The raw Data associated with the HTTP response, if any data was provided.
        public init(code: Int, data: Data?) {
            self.code = code
            self.data = data
        }
    }
}
// swiftlint:enable nesting

// MARK: - Common HTTP Header Field Keys

extension HTTP.HeaderKey {
    public static let accept = HTTP.HeaderKey(rawValue: "Accept")
    public static let acceptCharset = HTTP.HeaderKey(rawValue: "Accept-Charset")
    public static let acceptEncoding = HTTP.HeaderKey(rawValue: "Accept-Encoding")
    public static let acceptLanguage = HTTP.HeaderKey(rawValue: "Accept-Language")
    public static let acceptDatetime = HTTP.HeaderKey(rawValue: "Accept-Datetime")
    public static let authorization = HTTP.HeaderKey(rawValue: "Authorization")
    public static let contentLength = HTTP.HeaderKey(rawValue: "Content-Length")
    public static let contentMD5 = HTTP.HeaderKey(rawValue: "Content-MD5")
    public static let contentType = HTTP.HeaderKey(rawValue: "Content-Type")
    public static let date = HTTP.HeaderKey(rawValue: "Date")
    public static let userAgent = HTTP.HeaderKey(rawValue: "User-Agent")
}

// MARK: - Common HTTP Header Field Values

extension HTTP.HeaderValue {
    public static let applicationJSON = HTTP.HeaderValue(rawValue: "application/json")
    public static let applicationFormURLEncoded = HTTP.HeaderValue(rawValue: "application/x-www-form-urlencoded")
    public static let applicationXML = HTTP.HeaderValue(rawValue: "application/xml")
    public static let multipartForm = HTTP.HeaderValue(rawValue: "multipart/form-data")
    public static let textPlain = HTTP.HeaderValue(rawValue: "text/plain")
    public static let imagePNG = HTTP.HeaderValue(rawValue: "image/png")
    public static let imageJPEG = HTTP.HeaderValue(rawValue: "image/jpeg")
    public static let imageGIF = HTTP.HeaderValue(rawValue: "image/gif")
    public static let encodingCompress = HTTP.HeaderValue(rawValue: "compress")
    public static let encodingDeflate = HTTP.HeaderValue(rawValue: "deflate")
    public static let encodingExi = HTTP.HeaderValue(rawValue: "exi")
    public static let encodingGzip = HTTP.HeaderValue(rawValue: "gzip")
    public static let encodingIdentity = HTTP.HeaderValue(rawValue: "identity")
    public static let encodingPack200Gzip = HTTP.HeaderValue(rawValue: "pack200-gzip")
    public static let encodingBr = HTTP.HeaderValue(rawValue: "br")
    public static let passKit = HTTP.HeaderValue(rawValue: "application/vnd.apple.pkpass")
    public static let jsonAPI = HTTP.HeaderValue(rawValue: "application/vnd.api+json")
    
    public static func authorizationBearer(token: String) -> HTTP.HeaderValue {
        return HTTP.HeaderValue(rawValue: "Bearer \(token)")
    }
}

// MARK: - Hashable Implementations

extension HTTP.HeaderKey: Hashable {
    public var hashValue: Int {
        return rawValue.hashValue
    }
}

// MARK: - Equatable Implementations

extension HTTP.HeaderKey: Equatable {
    public static func == (lhs: HTTP.HeaderKey, rhs: HTTP.HeaderKey) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension HTTP.HeaderValue: Equatable {
    public static func == (lhs: HTTP.HeaderValue, rhs: HTTP.HeaderValue) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension HTTP.Response: Equatable {
    public static func == (lhs: HTTP.Response, rhs: HTTP.Response) -> Bool {
        return lhs.code == rhs.code && lhs.data == rhs.data
    }
}

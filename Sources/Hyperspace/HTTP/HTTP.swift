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
    public struct HeaderKey: RawRepresentable, Equatable, Hashable {
        public var rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
    
    /// Represents the value portion of a HTTP header field key-value pair.
    public struct HeaderValue: RawRepresentable, Equatable {
        public var rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
    
    /// Represents a HTTP status code.
    public enum Status {
        public struct Success: RawRepresentable, Equatable {
            public var rawValue: Int
            
            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
        }
        
        public struct Redirection: RawRepresentable, Equatable {
            public var rawValue: Int
            
            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
        }
        
        public struct ClientError: RawRepresentable, Equatable {
            public var rawValue: Int
            
            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
        }
        
        public struct ServerError: RawRepresentable, Equatable {
            public var rawValue: Int
            
            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
        }
        
        case unknown(Int)
        case success(Success)
        case redirection(Redirection)
        case clientError(ClientError)
        case serverError(ServerError)
        
        init(code: Int) {
            switch code {
            case 200..<300:
                self = .success(Success(rawValue: code))
            case 300..<400:
                self = .redirection(Redirection(rawValue: code))
            case 400..<500:
                self = .clientError(ClientError(rawValue: code))
            case 500..<600:
                self = .serverError(ServerError(rawValue: code))
            default:
                self = .unknown(code)
            }
        }
    }
    
    /// Represents a HTTP response.
    public struct Response: Equatable {

        /// The raw HTTP status code for this response.
        public let code: Int

        /// The raw Data associated with the HTTP response, if any data was provided.
        public let data: Data?

        /// The HTTP header fields for this response.
        public let headers: [String: String]?

        /// The parsed HTTP status associated with this response.
        public var status: HTTP.Status {
            return HTTP.Status(code: code)
        }

        /// A convenience property to encode the data associated with this response into a String. Can be useful for debugging.
        public var dataString: String? {
            return data.flatMap { String(data: $0, encoding: .utf8) }
        }

        /// Initialize a new Response with any given HTTP status code and Data.
        ///
        /// - Parameters:
        ///   - code: The raw HTTP status code for this response.
        ///   - data: The raw Data associated with the HTTP response, if any data was provided.
        ///   - headers: The HTTP header fields for this response.
        public init(code: Int, data: Data?, headers: [String: String]? = nil) {
            self.code = code
            self.data = data
            self.headers = headers
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

// MARK: - Common HTTP Status Codes

extension HTTP.Status.Success {
    public static let ok = HTTP.Status.Success(rawValue: 200)
    public static let created = HTTP.Status.Success(rawValue: 201)
    public static let accepted = HTTP.Status.Success(rawValue: 202)
    public static let nonAuthoritativeInformation = HTTP.Status.Success(rawValue: 203)
    public static let noContent = HTTP.Status.Success(rawValue: 204)
    public static let resetContent = HTTP.Status.Success(rawValue: 205)
    public static let partialContent = HTTP.Status.Success(rawValue: 206)
    public static let multiStatus = HTTP.Status.Success(rawValue: 207)
    public static let alreadyReported = HTTP.Status.Success(rawValue: 208)
    public static let imUsed = HTTP.Status.Success(rawValue: 226)
}

extension HTTP.Status.Redirection {
    public static let multipleChoices = HTTP.Status.Redirection(rawValue: 300)
    public static let movedPermanently = HTTP.Status.Redirection(rawValue: 301)
    public static let found = HTTP.Status.Redirection(rawValue: 302)
    public static let seeOther = HTTP.Status.Redirection(rawValue: 303)
    public static let notModified = HTTP.Status.Redirection(rawValue: 304)
    public static let useProxy = HTTP.Status.Redirection(rawValue: 305)
    public static let switchProxy = HTTP.Status.Redirection(rawValue: 306)
    public static let temporaryRedirect = HTTP.Status.Redirection(rawValue: 307)
    public static let permanentRedirect = HTTP.Status.Redirection(rawValue: 308)
}

extension HTTP.Status.ClientError {
    public static let badRequest = HTTP.Status.ClientError(rawValue: 400)
    public static let unauthorized = HTTP.Status.ClientError(rawValue: 401)
    public static let paymentRequired = HTTP.Status.ClientError(rawValue: 402)
    public static let forbidden = HTTP.Status.ClientError(rawValue: 403)
    public static let notFound = HTTP.Status.ClientError(rawValue: 404)
    public static let methodNotAllowed = HTTP.Status.ClientError(rawValue: 405)
    public static let notAcceptable = HTTP.Status.ClientError(rawValue: 406)
    public static let proxyAuthenticationRequired = HTTP.Status.ClientError(rawValue: 407)
    public static let requestTimeout = HTTP.Status.ClientError(rawValue: 408)
    public static let conflict = HTTP.Status.ClientError(rawValue: 409)
    public static let gone = HTTP.Status.ClientError(rawValue: 410)
    public static let lengthRequried = HTTP.Status.ClientError(rawValue: 411)
    public static let preconditionFailed = HTTP.Status.ClientError(rawValue: 412)
    public static let payloadTooLarge = HTTP.Status.ClientError(rawValue: 413)
    public static let uriTooLong = HTTP.Status.ClientError(rawValue: 414)
    public static let unsupportedMediaType = HTTP.Status.ClientError(rawValue: 415)
    public static let rangeNotSatisfiable = HTTP.Status.ClientError(rawValue: 416)
    public static let expectationFailed = HTTP.Status.ClientError(rawValue: 417)
    public static let imATeapot = HTTP.Status.ClientError(rawValue: 418)
    public static let misdirectedRequest = HTTP.Status.ClientError(rawValue: 421)
    public static let unproccessableEntity = HTTP.Status.ClientError(rawValue: 422)
    public static let locked = HTTP.Status.ClientError(rawValue: 423)
    public static let failedDependency = HTTP.Status.ClientError(rawValue: 424)
    public static let upgradeRequired = HTTP.Status.ClientError(rawValue: 426)
    public static let preconditionRequired = HTTP.Status.ClientError(rawValue: 428)
    public static let tooManyRequests = HTTP.Status.ClientError(rawValue: 429)
    public static let requestHeaderFieldsTooLarge = HTTP.Status.ClientError(rawValue: 431)
    public static let unavailableForLegalReasons = HTTP.Status.ClientError(rawValue: 451)
}

extension HTTP.Status.ServerError {
    public static let internalServerError = HTTP.Status.ServerError(rawValue: 500)
    public static let notImplemented = HTTP.Status.ServerError(rawValue: 501)
    public static let badGateway = HTTP.Status.ServerError(rawValue: 502)
    public static let serviceUnavailable = HTTP.Status.ServerError(rawValue: 503)
    public static let gatewayTimeout = HTTP.Status.ServerError(rawValue: 504)
    public static let httpVersionNotSupported = HTTP.Status.ServerError(rawValue: 505)
    public static let variantAlsoNegotiates = HTTP.Status.ServerError(rawValue: 506)
    public static let insufficientStorage = HTTP.Status.ServerError(rawValue: 507)
    public static let loopDetected = HTTP.Status.ServerError(rawValue: 508)
    public static let notExtended = HTTP.Status.ServerError(rawValue: 510)
    public static let networkAuthenticationRequired = HTTP.Status.ServerError(rawValue: 511)
}

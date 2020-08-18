//
//  Request.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Encapsulates all the necessary parameters to represent a request that can be sent over the network.
public struct Request<Response, Error: TransportFailureRepresentable>: Recoverable {
    
    // MARK: - Typealias
    public typealias Transformer = (TransportSuccess) -> Result<Response, Error>
    
    // MARK: - Properties
    
    /// The HTTP method to be use when executing this request.
    public var method: HTTP.Method
    
    /// The URL to use when executing this network request.
    public var url: URL
    
    /// The header field keys/values to use when executing this network request.
    public var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
    
    /// The payload body for this network request, if any.
    public var body: HTTP.Body?
    
    /// The cache policy to use when executing this network request.
    public var cachePolicy: URLRequest.CachePolicy
    
    /// The timeout to use when executing this network request.
    public var timeout: TimeInterval
    
    /// The creation strategy for generating a `URLRequest`. Can be customized by using the `.custom` case.
    public var urlRequestCreationStrategy: URLRequestCreationStrategy = .default
    
    /// The maximum number of attempts that this operation should make before completely aborting. This value is nil when there is no maximum.
    public var maxRecoveryAttempts: UInt?
    
    /// The number of recovery attempts that this operation has made
    public var recoveryAttemptCount: UInt = 0
    
    /// Attempts to parse the provided `TransportSuccess` into the associated response model type for this request.
    public var successTransformer: Transformer
    
    // MARK: - Initializer
    
    public init(method: HTTP.Method,
                url: URL,
                headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                body: HTTP.Body? = nil,
                cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
                timeout: TimeInterval = RequestDefaults.defaultTimeout,
                successTransformer: @escaping Transformer) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
        self.timeout = timeout
        self.successTransformer = successTransformer
    }
    
    // MARK: - Public
    public var urlRequest: URLRequest {
        return urlRequestCreationStrategy.urlRequest(using: self)
    }
    
    public func transform(success serviceSuccess: TransportSuccess) -> Result<Response, Error> {
        return successTransformer(serviceSuccess)
    }
    
    public func map<New>(_ responseTransformer: @escaping (Response) -> New) -> Request<New, Error> {
        return Request<New, Error>(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout) { transportSuccess in
            let originalResponse = self.transform(success: transportSuccess)
            return originalResponse.map(responseTransformer)
        }
    }

    public func mapError<New>(_ errorTransformer: @escaping (Error) -> New) -> Request<Response, New> {
        return Request<Response, New>(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout) { transportSuccess in
            let originalResponse = self.transform(success: transportSuccess)
            return originalResponse.mapError(errorTransformer)
        }
    }
}

// MARK: - EmptyResponse

/// A simple struct representing an empty server response to a request.
/// This is useful primarily for DELETE requests, in which case a "200" status with empty body is often the response.
public struct EmptyResponse {

    // NOTE: It would be ideal if the implicitly-generated memberwise initializer could automatically be available publicly instead of defining this manually.
    //       It may be possible someday - https://github.com/apple/swift-evolution/blob/master/proposals/0018-flexible-memberwise-initialization.md
    public init() { }
}

// MARK: - Request Defaults

public struct RequestDefaults {
    
    public static var defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    public static var defaultTimeout: TimeInterval = 30
}

// MARK: - Request Default Implementations

public extension Request {
    
    /// Adds the specified headers to the HTTP headers already attached to the `Request`.
    ///
    /// - Parameter additionalHeaders: The HTTP headers to add to the request
    /// - Returns: A new `NetworkReqest` with the combined HTTP headers. In the case of a collision, the value from `additionalHeaders` is preferred.
    func addingHeaders(_ additionalHeaders: [HTTP.HeaderKey: HTTP.HeaderValue]) -> Request {
        let modifiedHeaders = (headers ?? [:])?.merging(additionalHeaders) { return $1 }
        return usingHeaders(modifiedHeaders)
    }

    /// Modifies the HTTP headers on the `Request`.
    ///
    /// - Parameter headers: The HTTP headers to add to the request.
    /// - Returns: A new `NetworkReqest` with the given HTTP headers.
    func usingHeaders(_ headers: [HTTP.HeaderKey: HTTP.HeaderValue]?) -> Request {
        var copy = self
        copy.headers = headers
        return copy
    }

    /// Modifies the URL on the `Request`.
    ///
    /// - Parameter URL: The new URL to use with the request.
    /// - Returns: A new `NetworkReqest` with the given URL.
    func usingURL(_ url: URL) -> Request {
        var copy = self
        copy.url = url
        return copy
    }

    /// Modifies the HTTP body on the `Request`.
    ///
    /// - Parameter body: The HTTP body to add to the request.
    /// - Returns: A new `NetworkReqest` with the given HTTP body
    func usingBody(_ body: HTTP.Body?) -> Request {
        var copy = self
        copy.body = body
        return copy
    }
}

// MARK: - Request Default Implementations [EmptyResponse]

public extension Request where Response == EmptyResponse {
    
    init(method: HTTP.Method,
         url: URL,
         headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
         body: HTTP.Body? = nil,
         cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
         timeout: TimeInterval = RequestDefaults.defaultTimeout) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
        self.timeout = timeout
        self.successTransformer = { _ in .success(EmptyResponse()) }
    }
}

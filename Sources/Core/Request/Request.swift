//
//  Request.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Encapsulates all the necessary parameters to represent a request that can be sent over the network.
public struct Request<Response>: Recoverable {
    
    // MARK: - Typealiases
    public typealias Transformer = (TransportSuccess) async throws -> Response
    public typealias QuickRecoveryTransformer = (TransportFailure) -> TransportSuccess?

    @available(*, renamed: "QuickRecoveryTransformer")
    public typealias RecoveryTransformer = QuickRecoveryTransformer

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
    
    /// The maximum number of attempts this operation should make before completely aborting. A value of `nil` means there is no maximum.
    public var maxRecoveryAttempts: UInt? = RequestDefaults.defaultMaxRecoveryAttempts
    
    /// The number of recovery attempts this operation has made.
    public var recoveryAttemptCount: UInt = 0
    
    /// Attempts to parse the provided `TransportSuccess` into the associated response model type for this request.
    public var successTransformer: Transformer

    /// Validates a given `TransportSuccess` object, `throwing` if necessary. This is only called for otherwise successful requests, and the default implementation does nothing.
    public var successValidator: (TransportSuccess) throws -> Void = { _ in }

    /// Attempts to recover from a failure by converting a `TransportFailure` into a `TransportSucces`. The default implementation fails by returning nil.
    public var quickRecoveryTransformer: QuickRecoveryTransformer = { _ in nil }

    /// Attempts to recover from a failure by converting a `TransportFailure` into a `TransportSucces`. The default implementation fails by returning nil.
    @available(*, renamed: "quickRecoveryTransformer")
    public var recoveryTransformer: QuickRecoveryTransformer {
        get { quickRecoveryTransformer }
        set { quickRecoveryTransformer = newValue }
    }

    // MARK: - Initializer
    public init(method: HTTP.Method = .get,
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
    
    // MARK: - Interface
    public var urlRequest: URLRequest {
        return urlRequestCreationStrategy.urlRequest(using: self)
    }
    
    public func transform(success serviceSuccess: TransportSuccess) async throws -> Response {
        return try await successTransformer(serviceSuccess)
    }
    
    public func map<New>(_ responseTransformer: @escaping (Response) throws -> New) -> Request<New> {
        return .init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout) { transportSuccess in
            let originalResponse = try await transform(success: transportSuccess)
            return try responseTransformer(originalResponse)
        }
    }

    public func map<New>(_ responseTransformer: @escaping (TransportSuccess, Response) throws -> New) -> Request<New> {
        return .init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout) { transportSuccess in
            let responseResult = try await transform(success: transportSuccess)
            return try responseTransformer(transportSuccess, responseResult)
        }
    }

    public func throwing(_ responseTransformer: @escaping (TransportSuccess, Error) -> Error) -> Request {
        return .init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout) { transportSuccess in
            do {
                return try await transform(success: transportSuccess)
            } catch {
                throw responseTransformer(transportSuccess, error)
            }
        }
    }
}

// MARK: - Convenience Modifications
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

// MARK: - RequestDefaults
public struct RequestDefaults {
    
    public static var defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    public static var defaultDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    public static var defaultMaxRecoveryAttempts: UInt = 1
    public static var defaultTimeout: TimeInterval = 60
}

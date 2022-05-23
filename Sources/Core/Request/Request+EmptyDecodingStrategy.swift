//
//  Request+EmptyDecodingStrategy.swift
//  Hyperspace
//
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import Foundation

// MARK: - EmptyResponse

/// A simple struct representing an empty server response to a request. This is useful primarily for DELETE / PUT requests, in which case a "200" status with empty body is often the response.
public struct EmptyResponse {

    // NOTE: It would be ideal if the implicitly-generated memberwise initializer could automatically be available publicly instead of defining this manually.
    //       It may be possible someday - https://github.com/apple/swift-evolution/blob/master/proposals/0018-flexible-memberwise-initialization.md
    public init() { }
}

// MARK: - Empty Response Request Default Implementations
public extension Request where Response == EmptyResponse {

    static func withEmptyResponse(method: HTTP.Method = .get,
                                  url: URL,
                                  headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                                  body: HTTP.Body? = nil,
                                  cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
                                  timeout: TimeInterval = RequestDefaults.defaultTimeout,
                                  emptyDecodingStrategy: EmptyDecodingStrategy = .default) -> Request {
        return Request(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout,
                       successTransformer: Self.successTransformer(for: emptyDecodingStrategy))
    }

    // MARK: - Convenience Transformers
    static func successTransformer(for emptyDecodingStrategy: EmptyDecodingStrategy) -> Transformer {
        return emptyDecodingStrategy.transformer
    }
}

// MARK: = Request.EmptyDecodingStrategy
public extension Request where Response == EmptyResponse {

    struct EmptyDecodingStrategy {

        // MARK: - Properties
        let transformer: Transformer

        // MARK: - Preset

        /// The default `EmptyDecodingStrategy` will always return a successful `EmptyResponse` object given a successful transport.
        public static var `default`: EmptyDecodingStrategy {
            return EmptyDecodingStrategy { _ in
                return EmptyResponse()
            }
        }

        /// The validating `EmptyDecodingStrategy` will first validate that the response data is either nil or empty before returning an `EmptyResponse`.
        public static var validatedEmpty: EmptyDecodingStrategy {
            return EmptyDecodingStrategy { transportSuccess in
                guard transportSuccess.body.map(\.isEmpty) ?? true else {
                    throw DecodingFailure.invalidEmptyResponse(transportSuccess.response)
                }

                return EmptyResponse()
            }
        }
    }
}

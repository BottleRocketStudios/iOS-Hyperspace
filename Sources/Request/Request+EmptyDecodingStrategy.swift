//
//  Request+EmptyDecodingStrategy.swift
//  Hyperspace
//
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import Foundation

// MARK: - Empty Response Request Default Implementations
public extension Request where Response == Void {

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

// MARK: - Request.EmptyDecodingStrategy
public extension Request where Response == Void {

    struct EmptyDecodingStrategy {

        // MARK: - Properties
        let transformer: Transformer

        // MARK: - Preset

        /// The default `EmptyDecodingStrategy` will always return a successful `EmptyResponse` object given a successful transport.
        public static var `default`: EmptyDecodingStrategy {
            return EmptyDecodingStrategy { _ in
                return Void()
            }
        }

        /// The validating `EmptyDecodingStrategy` will first validate that the response data is either nil or empty before returning an `EmptyResponse`.
        public static func validatedEmpty(throwing errorCreator: @escaping (TransportSuccess) -> Error) -> EmptyDecodingStrategy {
            return EmptyDecodingStrategy { transportSuccess in
                guard transportSuccess.body.map(\.isEmpty) ?? true else {
                    throw errorCreator(transportSuccess)
                }

                return Void()
            }
        }
    }
}

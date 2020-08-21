//
//  Request+EmptyDecodingStrategy.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 8/18/20.
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import Foundation

// MARK: - Empty Response Request Default Implementations

public extension Request where Response == EmptyResponse {

    struct EmptyDecodingStrategy {

        // MARK: - Properties
        let transformer: (@escaping (DecodingFailure) -> Error) -> Transformer

        // MARK: - Interface
        func transformer(using decodingFailureTransformer: @escaping DecodingFailureTransformer) -> Transformer {
            return transformer(decodingFailureTransformer)
        }

        // MARK: - Preset
        public static func custom(_ transformer: @escaping (DecodingFailureTransformer) -> Transformer) -> EmptyDecodingStrategy {
            return EmptyDecodingStrategy(transformer: transformer)
        }

        /// The default `EmptyDecodingStrategy` will always return a successful `EmptyResponse` object given a successful transport.
        public static var `default`: EmptyDecodingStrategy {
            return EmptyDecodingStrategy { _ -> Transformer in
                return { _ in .success(EmptyResponse()) }
            }
        }

        /// The validating `EmptyDecodingStrategy` will first validate that the response data is either nil or empty before returning an `EmptyResponse`.
        public static var validatedEmpty: EmptyDecodingStrategy {
            return EmptyDecodingStrategy { decodingFailureTransformer -> Transformer in
                return { transportSuccess in
                    guard transportSuccess.body.map({ $0.isEmpty }) ?? true else {
                        return .failure(decodingFailureTransformer(.invalidEmptyResponse(transportSuccess.response)))
                    }

                    return .success(EmptyResponse())
                }
            }
        }
    }

    // MARK: - Initializer

    static func withEmptyResponse(method: HTTP.Method,
                                  url: URL,
                                  headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                                  body: HTTP.Body? = nil,
                                  cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
                                  timeout: TimeInterval = RequestDefaults.defaultTimeout,
                                  emptyDecodingStrategy: EmptyDecodingStrategy = .default,
                                  decodingFailureTransformer: @escaping DecodingFailureTransformer) -> Request {
        return Request(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout,
                       successTransformer: Request.successTransformer(for: emptyDecodingStrategy, decodingFailureTransformer: decodingFailureTransformer))
    }

    // MARK: - Convenience Transformers

    static func successTransformer(for emptyDecodingStrategy: EmptyDecodingStrategy, decodingFailureTransformer: @escaping DecodingFailureTransformer) -> Transformer {
        return emptyDecodingStrategy.transformer(using: decodingFailureTransformer)
    }
}

public extension Request where Response == EmptyResponse, Error: DecodingFailureRepresentable {

    static func withEmptyResponse(method: HTTP.Method,
                                  url: URL,
                                  headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                                  body: HTTP.Body? = nil,
                                  cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
                                  timeout: TimeInterval = RequestDefaults.defaultTimeout,
                                  emptyDecodingStrategy: EmptyDecodingStrategy = .default) -> Request {
        return Request(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout,
                       successTransformer: Request.successTransformer(for: emptyDecodingStrategy))
    }

    // MARK: - Convenience Transformers

    static func successTransformer(for emptyDecodingStrategy: EmptyDecodingStrategy) -> Transformer {
        return emptyDecodingStrategy.transformer(using: Error.init)
    }
}

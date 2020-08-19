//
//  Request+Decodable.swift
//  Hyperspace
//
//  Created by William McGinty on 3/7/20.
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import Foundation

// MARK: - Request Default Implementations

public extension Request where Response: Decodable, Error: DecodingFailureRepresentable {
    
    // MARK: - Initializer
    
    init(method: HTTP.Method,
         url: URL,
         headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
         body: HTTP.Body? = nil,
         cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
         timeout: TimeInterval = RequestDefaults.defaultTimeout,
         decoder: JSONDecoder = JSONDecoder()) {
        self.init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout, successTransformer: Request.successTransformer(for: decoder))
    }
    
    // MARK: - Convenience Transformers

    static func successTransformer(for decoder: JSONDecoder) -> Transformer {
        return successTransformer(for: decoder, errorTransformer: Error.init)
    }
    
    static func successTransformer(for decoder: JSONDecoder, errorTransformer: @escaping (DecodingError, Decodable.Type, HTTP.Response) -> Error) -> Transformer {
        return { transportSuccess in
            do {
                let decodedResponse = try decoder.decode(Response.self, from: transportSuccess.body ?? Data())
                return .success(decodedResponse)
                
            } catch let error as DecodingError {
                return .failure(errorTransformer(error, Response.self, transportSuccess.response))
                
            } catch {
                return .failure(errorTransformer(.dataCorrupted(.init(codingPath: [], debugDescription: error.localizedDescription)), Response.self, transportSuccess.response))
            }
        }
    }
}

// MARK: - Empty Response Request Default Implementations

public extension Request where Response == EmptyResponse {

    struct EmptyDecodingStrategy {

        // MARK: - Properties
        let transformer: (@escaping DecodingErrorTransformer) -> Transformer

        // MARK: - Interface
        func transform(using errorTransformer: @escaping DecodingErrorTransformer) -> Transformer {
            return transformer(errorTransformer)
        }

        // MARK: - Preset

        public static func custom(_ transformer: @escaping (DecodingErrorTransformer) -> Transformer) -> EmptyDecodingStrategy {
            return EmptyDecodingStrategy(transformer: transformer)
        }

        public static var `default`: EmptyDecodingStrategy {
            return EmptyDecodingStrategy { _ -> (TransportSuccess) -> Result<EmptyResponse, Error> in
                return { _ in .success(EmptyResponse()) }
            }
        }

        public static var validatedEmpty: EmptyDecodingStrategy {
            return EmptyDecodingStrategy { decodingErrorTransformer -> (TransportSuccess) -> Result<EmptyResponse, Error> in
                return { transportSuccess in
                    guard transportSuccess.body.map(\.isEmpty) ?? true else {
                        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Expected an empty response, but content found."))
                        //let error = decodingErrorTransformer(decodingError, EmptyResponse.self, transportSuccess.response)
                        //return .failure(error)
                        fatalError()
                    }

                    return .success(EmptyResponse())
                }
            }
        }
    }

    // MARK: - Initializer

    init(method: HTTP.Method,
         url: URL,
         headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
         body: HTTP.Body? = nil,
         cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
         timeout: TimeInterval = RequestDefaults.defaultTimeout,
         emptyDecodingStrategy: EmptyDecodingStrategy = .default,
         decodingErrorTransformer: @escaping DecodingErrorTransformer) {
        self.init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout,
                  successTransformer: Request.successTransformer(for: emptyDecodingStrategy, errorTransformer: decodingErrorTransformer))
    }

    // MARK: - Convenience Transformers

    static func successTransformer(for emptyDecodingStrategy: EmptyDecodingStrategy, errorTransformer: @escaping (DecodingError, Decodable.Type, HTTP.Response) -> Error) -> Transformer {
        return emptyDecodingStrategy.transform(using: errorTransformer)
    }
}

public extension Request where Response == EmptyResponse, Error: DecodingFailureRepresentable {

    init(method: HTTP.Method,
         url: URL,
         headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
         body: HTTP.Body? = nil,
         cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
         timeout: TimeInterval = RequestDefaults.defaultTimeout,
         emptyDecodingStrategy: EmptyDecodingStrategy = .default) {
        self.init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout, successTransformer: Request.successTransformer(for: emptyDecodingStrategy))
    }

    // MARK: - Convenience Transformers

    static func successTransformer(for emptyDecodingStrategy: EmptyDecodingStrategy) -> Transformer {
        return successTransformer(for: emptyDecodingStrategy, errorTransformer: Error.init)
    }
}

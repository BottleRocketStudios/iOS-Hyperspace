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
        func transform(using decodingFailureTransformer: @escaping DecodingFailureTransformer) -> Transformer {
            return transformer(decodingFailureTransformer)
        }

        // MARK: - Preset
        public static func custom(_ transformer: @escaping (DecodingFailureTransformer) -> Transformer) -> EmptyDecodingStrategy {
            return EmptyDecodingStrategy(transformer: transformer)
        }

        public static var `default`: EmptyDecodingStrategy {
            return EmptyDecodingStrategy { _ -> Transformer in
                return { _ in .success(EmptyResponse()) }
            }
        }

        public static var validatedEmpty: EmptyDecodingStrategy {
            return EmptyDecodingStrategy { decodingFailureTransformer -> Transformer in
                return { transportSuccess in
                    guard transportSuccess.body.map(\.isEmpty) ?? true else {
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
        return emptyDecodingStrategy.transform(using: decodingFailureTransformer)
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
        return emptyDecodingStrategy.transform(using: Error.init)
    }
}

enum MyError: DecodingFailureRepresentable {
    case networkResponseCodeMismatch

    var failureResponse: HTTP.Response? { return nil }
    var transportError: TransportError? { return nil }

    init(transportFailure: TransportFailure) {
        self = .networkResponseCodeMismatch
    }

    init(decodingFailure: DecodingFailure) {
        self = .networkResponseCodeMismatch
    }
}

extension Request.EmptyDecodingStrategy where Response == EmptyResponse, Error == MyError {

    struct NetworkResponse: Decodable {
        let returnCode: Int
        let message: String
    }

    static var validatingNetworkResponse: Request.EmptyDecodingStrategy {
        return Request.EmptyDecodingStrategy { decodingFailureTransformer -> Request.Transformer in
            return { transportSuccess in

                do {
                    let networkResponse =  try JSONDecoder().decode(NetworkResponse.self, from: transportSuccess.body ?? Data())
                    guard networkResponse.returnCode == 200 else {
                        return .failure(MyError.networkResponseCodeMismatch)
                    }

                    return .success(EmptyResponse())

                } catch let decodingError as DecodingError {
                    let context = DecodingFailure.Context(decodingError: decodingError, failingType: NetworkResponse.self, response: transportSuccess.response)
                    return .failure(decodingFailureTransformer(.decodingError(context)))

                } catch {
                    let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: error.localizedDescription))
                    let context = DecodingFailure.Context(decodingError: decodingError, failingType: NetworkResponse.self, response: transportSuccess.response)
                    return .failure(decodingFailureTransformer(.decodingError(context)))
                }
            }
        }
    }
}

extension Request where Response == EmptyResponse, Error == MyError {

    static func delete(withID id: Int) -> Request<EmptyResponse, MyError> {
        return Request.withEmptyResponse(method: .delete, url: URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!, emptyDecodingStrategy: .validatingNetworkResponse)
    }
}

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
         decoder: JSONDecoder = RequestDefaults.defaultDecoder) {
        self.init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout, successTransformer: Request.successTransformer(for: decoder))
    }
    
    // MARK: - Convenience Transformers

    static func successTransformer(for decoder: JSONDecoder) -> Transformer {
        return successTransformer(for: decoder, errorTransformer: Error.init)
    }
    
    static func successTransformer(for decoder: JSONDecoder, errorTransformer: @escaping DecodingFailureTransformer) -> Transformer {
        return { transportSuccess in
            do {
                let decodedResponse = try decoder.decode(Response.self, from: transportSuccess.body ?? Data())
                return .success(decodedResponse)
                
            } catch let error as DecodingError {
                let context = DecodingFailure.Context(decodingError: error, failingType: Response.self, response: transportSuccess.response)
                return .failure(errorTransformer(.decodingError(context)))
                
            } catch {
                // Received an unexpected non-`DecodingError` from the `JSONDecoder`. Generate a default `DecodingError` and pass that along.
                return .failure(errorTransformer(.genericFailure(decoding: Response.self, from: transportSuccess.response, debugDescription: error.localizedDescription)))
            }
        }
    }
}

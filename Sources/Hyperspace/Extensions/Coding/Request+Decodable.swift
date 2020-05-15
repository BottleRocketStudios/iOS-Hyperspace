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
    
    typealias Transformer = (TransportSuccess) -> Result<Response, Error>

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
                let decodedResponse = try decoder.decode(Response.self, from: transportSuccess.data)
                return .success(decodedResponse)
                
            } catch let error as DecodingError {
                return .failure(errorTransformer(error, Response.self, transportSuccess.response))
                
            } catch {
                let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: error.localizedDescription))
                return .failure(errorTransformer(decodingError, Response.self, transportSuccess.response))
            }
        }
    }
}

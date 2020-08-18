//
//  Request.URLRequestCreationStrategy.swift
//  Hyperspace-iOS
//
//  Created by William McGinty on 3/6/20.
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public extension Request {
    
    // MARK: - URLRequestCreationStrategy

    struct URLRequestCreationStrategy {

        // MARK: - Properties
        let creationBlock: (Request) -> URLRequest

        // MARK: - Interface
        func urlRequest(using request: Request) -> URLRequest {
            return creationBlock(request)
        }

        // MARK: - Preset

        public static func custom(_ creationBlock: @escaping (Request) -> URLRequest) -> URLRequestCreationStrategy {
            return URLRequestCreationStrategy(creationBlock: creationBlock)
        }

        public static var `default`: URLRequestCreationStrategy {
            return URLRequestCreationStrategy { request -> URLRequest in
                var urlRequest = URLRequest(url: request.url, cachePolicy: request.cachePolicy, timeoutInterval: request.timeout)
                urlRequest.httpMethod = request.method.rawValue
                urlRequest.httpBody = request.body?.data

                // Transform the headers from [HTTP.HeaderKey: HTTP.HeaderValue] to [String: String], preferring those explicitly added to the request
                let mergedHeaders = (request.headers ?? [:]).merging(request.body?.additionalHeaders ?? [:]) { lhs, _ in lhs }
                let rawHeaders: [String: String] = Dictionary(uniqueKeysWithValues: mergedHeaders.map { ($0.rawValue, $1.rawValue) })
                urlRequest.allHTTPHeaderFields = rawHeaders

                return urlRequest
            }
        }
    }
}

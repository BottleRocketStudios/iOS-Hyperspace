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
    
    enum URLRequestCreationStrategy {
        case custom((Request) -> URLRequest)
        
        func urlRequest(using request: Request) -> URLRequest {
            switch self {
            case .custom(let creator): return creator(request)
            }
        }
        
        /// The `default` strategy applies the `Requests` URL, cache policy, timeout as well as the HTTP method, body and headers.
        public static var `default`: URLRequestCreationStrategy {
            return .custom { request -> URLRequest in
                var urlRequest = URLRequest(url: request.url, cachePolicy: request.cachePolicy, timeoutInterval: request.timeout)
                urlRequest.httpMethod = request.method.rawValue
                urlRequest.httpBody = request.body?.data
                
                // Transform the headers from [HTTP.HeaderKey: HTTP.HeaderValue] to [String: String]
                let rawHeaders: [String: String] = Dictionary(uniqueKeysWithValues: (request.headers ?? [:]).map { ($0.rawValue, $1.rawValue) })
                urlRequest.allHTTPHeaderFields = rawHeaders
                
                return urlRequest
            }
        }
    }
}

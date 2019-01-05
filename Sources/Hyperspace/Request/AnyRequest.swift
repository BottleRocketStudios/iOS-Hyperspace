//
//  AnyRequest.swift
//  Hyperspace
//
//  Created by Will McGinty on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Result

// MARK: - AnyRequest Default Implementations

extension Request where ResponseType: Decodable, ErrorType: DecodingFailureInitializable {
    
    public init(method: HTTP.Method,
                url: URL,
                headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                body: Data? = nil,
                cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
                timeout: TimeInterval = RequestDefaults.defaultTimeout,
                decoder: JSONDecoder = JSONDecoder()) {
        self.init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout, transformer: RequestDefaults.successTransformer(for: decoder))
    }
}

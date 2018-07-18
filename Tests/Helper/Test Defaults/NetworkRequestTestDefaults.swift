//
//  RequestTestDefaults.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/29/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace
import Result

class RequestTestDefaults {
    struct DefaultModel: Codable, Equatable {
        let title: String
    }
    
    struct DefaultRequest<T: Decodable>: Request {
        
        // swiftlint:disable nesting
        typealias ResponseType = T
        typealias ErrorType = MockBackendServiceError
        // swiftlint:enable nesting
        
        var method: HTTP.Method = .get
        var url: URL = RequestTestDefaults.defaultURL
        var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
        var body: Data?
        var cachePolicy: URLRequest.CachePolicy = RequestTestDefaults.defaultCachePolicy
        var timeout: TimeInterval = RequestTestDefaults.defaultTimeout
    }
    
    static let defaultModel = DefaultModel(title: "test")
    static let defaultModelJSONData: Data = {
        let jsonEncoder = JSONEncoder()
        return try! jsonEncoder.encode(defaultModel)
    }()
    static let defaultURL = URL(string: "https://apple.com")!
    static let defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    static let defaultTimeout: TimeInterval = 1.0
}

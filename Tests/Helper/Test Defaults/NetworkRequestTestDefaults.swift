//
//  RequestTestDefaults.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/29/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace

class RequestTestDefaults {
    
    struct DefaultModel: Codable, Equatable {
        let title: String
    }
    
    static func defaultRequest<T: Decodable>() -> Request<T, MockBackendServiceError> {
        return Request(method: .get, url: RequestTestDefaults.defaultURL, cachePolicy: RequestTestDefaults.defaultCachePolicy, timeout: RequestTestDefaults.defaultTimeout)
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

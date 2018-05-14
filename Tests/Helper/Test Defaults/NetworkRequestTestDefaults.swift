//
//  NetworkRequestTestDefaults.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/29/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace
import Result

class NetworkRequestTestDefaults {
    struct DefaultModel: Codable {
        let title: String
    }
    
    struct DefaultRequest<T: Decodable>: NetworkRequest {
        
        // swiftlint:disable nesting
        typealias ResponseType = T
        typealias ErrorType = MockBackendServiceError
        // swiftlint:enable nesting
        
        var method: HTTP.Method = .get
        var url: URL = NetworkRequestTestDefaults.defaultURL
        var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
        var body: Data?
        var cachePolicy: URLRequest.CachePolicy = NetworkRequestTestDefaults.defaultCachePolicy
        var timeout: TimeInterval = NetworkRequestTestDefaults.defaultTimeout
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

extension NetworkRequestTestDefaults.DefaultModel: Equatable {
    public static func == (lhs: NetworkRequestTestDefaults.DefaultModel, rhs: NetworkRequestTestDefaults.DefaultModel) -> Bool {
        return lhs.title == rhs.title
    }
}

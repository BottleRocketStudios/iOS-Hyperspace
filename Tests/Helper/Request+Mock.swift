//
//  Request+Mock.swift
//  Hyperspace
//
//  Created by Will McGinty on 7/26/23.
//  Copyright © 2023 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace

// MARK: - Request + Convenience
extension Request {

    static var simpleGET: Request<String> {
        return .init(method: .get, url: URL(string: "http://apple.com")!, cachePolicy: .useProtocolCachePolicy, timeout: 1)
    }

    static var simplePOST: Request<String> {
        return .init(method: .post, url: URL(string: "http://apple.com")!, cachePolicy: .useProtocolCachePolicy, timeout: 1)
    }

    static var cachePolicyAndTimeoutRequest: Request<Void> {
        return .withEmptyResponse(method: .get, url: URL(string: "http://apple.com")!)
    }
}

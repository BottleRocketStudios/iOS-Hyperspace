//
//  URL+Additions.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

// MARK: - [URLQueryItem] Convenience
extension Array where Element == URLQueryItem {

    var queryString: String? {
        var components = URLComponents()
        components.queryItems = self

        return components.query
    }
}

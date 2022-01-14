//
//  URLQueryItem+Extensions.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public extension URLQueryItem {
    
    static func generateRawQueryParametersString(from queryParameters: [URLQueryItem]) -> String {
        // Start with the empty string, appending "&<key>=<value>" for each key-value pair (except the first, which doesn't have the '&' suffix).
        return queryParameters.reduce("") { (partialResult, queryItem) -> String in
            let nextPartialResult = (partialResult.isEmpty ? "" : "\(partialResult)&")
            
            guard let queryValue = queryItem.value else {
                return nextPartialResult + "\(queryItem.name)"
            }

            return nextPartialResult + "\(queryItem.name)=\(queryValue)"
        }
    }
}

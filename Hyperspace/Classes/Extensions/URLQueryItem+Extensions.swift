//
//  URLQueryItem+Extensions.swift
//  Hyperspace
//
//  Created by Tyler Milner on 8/4/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

extension URLQueryItem {
    public static func generateRawQueryParametersString(from queryParameters: [URLQueryItem]) -> String {
        // Start with the empty string, appending "&<key>=<value>" for each key-value pair (except the first, which doesn't have the '&' suffix).
        return queryParameters.reduce("", { (partialResult, queryItem) -> String in
            let nextPartialResult = (partialResult.isEmpty ? "" : "\(partialResult)&")
            
            if let queryValue = queryItem.value {
                return nextPartialResult + "\(queryItem.name)=\(queryValue)"
            } else {
                return nextPartialResult + "\(queryItem.name)"
            }
        })
    }
}

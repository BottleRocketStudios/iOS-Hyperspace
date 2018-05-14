//
//  URL+Additions.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

extension URL {
    
    func appendingQueryString(_ queryString: String) -> URL {
        // Conditionally add the '?' character
        let fullQueryString = queryString.isEmpty ? "" : "?\(queryString)"
        
        guard let url = URL(string: "\(absoluteString)\(fullQueryString)") else { fatalError("Unable to create \(URL.self) from query string: \(fullQueryString)") }
        return url
    }
}

public extension URL {
    
    /// Represents the strategy used to encode query parameters in the URL.
    // swiftlint:disable nesting
    public enum QueryParameterEncodingStrategy {
        public typealias QueryStringEncodingBlock = (String) -> String
        
        case urlQueryAllowedCharacterSet
        case custom(QueryStringEncodingBlock)
        
        func encode(string: String) -> String {
            switch self {
            case .urlQueryAllowedCharacterSet:
                guard let encodedQueryString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { fatalError("Unable to encode query parameters for \(self)") }
                return encodedQueryString
            case .custom(let encodingBlock):
                return encodingBlock(string)
            }
        }
    }
    // swiftlint:enable nesting
    
    /// Encodes and appends an array of query items to a URL, returning a new URL with the query appended.
    ///
    /// - Parameters:
    ///   - items: An array of `URLQueryItem` to be encoded into the URL query string.
    ///   - encodingStrategy: The appropriate type of `URL.QueryParameterEncodingStrategy` to be used for encoding.
    /// - Returns: Returns the resulting URL after query encoding and addition.
    func appendingQueryItems(_ items: [URLQueryItem], using encodingStrategy: QueryParameterEncodingStrategy = .urlQueryAllowedCharacterSet) -> URL {
        let queryString = URLQueryItem.generateRawQueryParametersString(from: items)
        return appendingQueryString(encodingStrategy.encode(string: queryString))
    }
}

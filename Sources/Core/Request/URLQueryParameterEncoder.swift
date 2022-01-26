//
//  URLQueryParameterEncoder.swift
//  Hyperspace
//
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public struct URLQueryParameterEncoder {
    
    public init() { /* No op */ }
    
    /// Represents the strategy used to encode query parameters in the URL.
    // swiftlint:disable nesting
    public enum EncodingStrategy {
        public typealias EncodingBlock = (String) -> String
        
        case urlQueryAllowedCharacterSet
        case custom(EncodingBlock)
        
        func encode(string: String) -> String {
            switch self {
            case .urlQueryAllowedCharacterSet:
                guard let encodedQueryString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { fatalError("Unable to encode query parameters for \(self).") }
                return encodedQueryString
            case .custom(let encodingBlock):
                return encodingBlock(string)
            }
        }
    }
    // swiftlint:enable nesting
    
    /// The encoding strategy to be used in encoding
    public var encodingStrategy: EncodingStrategy = .urlQueryAllowedCharacterSet
    
    /// Encodes an array of `URLQueryItem` and returns the query string.
    ///
    /// - Parameter queryItems: The array of `URLQueryItem` to be encoded.
    /// - Returns: The encoded query string.
    public func encode(_ queryItems: [URLQueryItem]) -> String {
        let queryString = URLQueryItem.generateRawQueryParametersString(from: queryItems)
        return encode(queryString)
    }
    
    /// Encodes and returns a new query string.
    ///
    /// - Parameter queryItems: The query string to be encoded.
    /// - Returns: The encoded query string.
    public func encode(_ queryString: String) -> String {
        return encodingStrategy.encode(string: queryString)
    }
}

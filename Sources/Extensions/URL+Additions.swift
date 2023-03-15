//
//  URL+Additions.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

@available(*, deprecated)
public extension URL {

    func appendingQueryString(_ queryString: String?) -> URL {
        guard let queryString = queryString else { return self }
        guard query != nil else {
            // The URL does not already contain a query
            let fullQueryString = queryString.isEmpty ? "" : "?\(queryString)"
            guard let url = URL(string: "\(absoluteString)\(fullQueryString)") else { fatalError("Unable to create \(URL.self) from query string: \(fullQueryString)") }
            return url
        }
        
        // The URL already contains a query
        let fullQueryString = queryString.isEmpty ? "" : "&\(queryString)"
        guard let url = URL(string: "\(absoluteString)\(fullQueryString)") else { fatalError("Unable to create \(URL.self) from query string: \(fullQueryString)") }
        return url
    }

    func appendingQueryItems(_ queryItems: [URLQueryItem], using encoder: URLQueryParameterEncoder = URLQueryParameterEncoder()) -> URL {
        return appendingQueryString(encoder.encode(queryItems))
    }
}

// MARK: - URLQueryParameterEncoder
@available(*, deprecated)
public struct URLQueryParameterEncoder {

    public init() { /* No op */ }

    /// Represents the strategy used to encode query parameters in the URL.
    public enum EncodingStrategy {
        case urlQueryAllowedCharacterSet
        case custom((String) -> String?)

        func encode(string: String) -> String? {
            switch self {
            case .urlQueryAllowedCharacterSet: return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            case .custom(let encodingBlock): return encodingBlock(string)
            }
        }
    }

    /// The encoding strategy to be used in encoding
    public var encodingStrategy: EncodingStrategy = .urlQueryAllowedCharacterSet

    /// Encodes an array of `URLQueryItem` and returns the query string.
    ///
    /// - Parameter queryItems: The array of `URLQueryItem` to be encoded.
    /// - Returns: The encoded query string.
    public func encode(_ queryItems: [URLQueryItem]) -> String? {
        return queryItems.queryString.flatMap(encode)
    }

    /// Encodes and returns a new query string.
    ///
    /// - Parameter queryItems: The query string to be encoded.
    /// - Returns: The encoded query string.
    public func encode(_ queryString: String) -> String? {
        return encodingStrategy.encode(string: queryString)
    }
}

// MARK: - [URLQueryItem] Convenience
extension Array where Element == URLQueryItem {

    var queryString: String? {
        var components = URLComponents()
        components.queryItems = self

        return components.query
    }
}

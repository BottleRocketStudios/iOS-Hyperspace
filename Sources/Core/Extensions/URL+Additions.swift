//
//  URL+Additions.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public extension URL {
    
    func appendingQueryString(_ queryString: String) -> URL {
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

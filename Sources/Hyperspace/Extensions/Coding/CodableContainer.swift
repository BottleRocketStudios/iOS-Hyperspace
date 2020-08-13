//
//  DecodableContainer.swift
//  Hyperspace
//
//  Created by Will McGinty on 11/27/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

// Represents something that is capable of Encoding itself (using `Swift.Encodable`) and contains a child type.
public protocol EncodableContainer: Encodable {

    /// The type of the `Swift.Encodable` child element.
    associatedtype Contained: Encodable
    
    /// Initializes a new instance of the container.
    /// - Parameter element: The element to be placed inside the container.
    init(element: Contained)
    
    /// Retrieve the child type from its container.
    var element: Contained { get }
}

/// Represents something that is capable of Decoding itself (using Swift.Decodable) and contains a child type.
public protocol DecodableContainer: Decodable {
    
    /// The type of the Swift.Decodable child element.
    associatedtype Contained: Decodable
    
    /// Retrieve the child type from its container.
    var element: Contained { get }
}

/// Represents something that is capable of both Encoding and Decoding itself and contains a child type.
public typealias CodableContainer = DecodableContainer & EncodableContainer

// MARK: - Request Default Implementations

public extension Request where Response: Decodable, Error: DecodingFailureRepresentable {
    
    // MARK: - Initializer
    
    init<Container: DecodableContainer>(method: HTTP.Method,
                                        url: URL,
                                        headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                                        body: HTTP.Body? = nil,
                                        cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
                                        timeout: TimeInterval = RequestDefaults.defaultTimeout,
                                        decoder: JSONDecoder = JSONDecoder(),
                                        containerType: Container.Type) where Container.Contained == Response {
        self.init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout,
                  successTransformer: Request.successTransformer(for: decoder, with: containerType))
    }
    
    // MARK: - Convenience Transformers
    
    static func successTransformer<C: DecodableContainer>(for decoder: JSONDecoder, with containerType: C.Type) -> (TransportSuccess) -> Result<Response, Error> where C.Contained == Response {
        return successTransformer(for: decoder, with: containerType, errorTransformer: Error.init)
    }
    
    static func successTransformer<C: DecodableContainer>(for decoder: JSONDecoder, with containerType: C.Type,
                                                          errorTransformer: @escaping (DecodingError, Decodable.Type, HTTP.Response) -> Error) -> (TransportSuccess) -> Result<Response, Error> where C.Contained == Response {
        return { transportSuccess in
            do {
                let decodedResponse = try decoder.decode(C.self, from: transportSuccess.data)
                return .success(decodedResponse.element)
                
            } catch let error as DecodingError {
                return .failure(errorTransformer(error, C.self, transportSuccess.response))
                
            } catch {
                return .failure(errorTransformer(.dataCorrupted(.init(codingPath: [], debugDescription: error.localizedDescription)), C.self, transportSuccess.response))
            }
        }
    }
}

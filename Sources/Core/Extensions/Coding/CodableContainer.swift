//
//  DecodableContainer.swift
//  Hyperspace
//
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
                                        decoder: JSONDecoder = RequestDefaults.defaultDecoder,
                                        containerType: Container.Type) where Container.Contained == Response {
        self.init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout,
                  successTransformer: Request.successTransformer(for: decoder, with: containerType))
    }
    
    // MARK: - Convenience Transformers
    
    static func successTransformer<C: DecodableContainer>(for decoder: JSONDecoder, with containerType: C.Type) -> Transformer where C.Contained == Response {
        return successTransformer(for: decoder, with: containerType, errorTransformer: Error.init)
    }
    
    static func successTransformer<C: DecodableContainer>(for decoder: JSONDecoder, with containerType: C.Type,
                                                          errorTransformer: @escaping DecodingFailureTransformer) -> Transformer where C.Contained == Response {
        return { transportSuccess in
            do {
                let decodedResponse = try decoder.decode(Response.self, from: transportSuccess.body ?? Data(), with: C.self)
                return .success(decodedResponse)
                
            } catch let error as DecodingError {
                let context = DecodingFailure.Context(decodingError: error, failingType: C.self, response: transportSuccess.response)
                return .failure(errorTransformer(.decodingError(context)))
                
            } catch {
                // Received an unexpected non-`DecodingError` from the `JSONDecoder`. Generate a default `DecodingError` and pass that along.
                return .failure(errorTransformer(.genericFailure(decoding: Response.self, from: transportSuccess.response, debugDescription: error.localizedDescription)))
            }
        }
    }
}

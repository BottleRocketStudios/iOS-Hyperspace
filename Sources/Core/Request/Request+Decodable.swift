//
//  Request+Decodable.swift
//  Hyperspace
//
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import Foundation

// MARK: - CodableContainer

/// Represents something that is capable of both Encoding and Decoding itself and contains a child type.
public typealias CodableContainer = DecodableContainer & EncodableContainer

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

// MARK: - Request + Decodable
public extension Request where Response: Decodable {

    // MARK: - Initializers
    init(method: HTTP.Method = .get,
         url: URL,
         headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
         body: HTTP.Body? = nil,
         cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
         timeout: TimeInterval = RequestDefaults.defaultTimeout,
         decoder: JSONDecoder = RequestDefaults.defaultDecoder) {
        self.init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout,
                  successTransformer: Self.successTransformer(for: decoder))
    }

    init<Container: DecodableContainer>(method: HTTP.Method = .get,
                                        url: URL,
                                        headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                                        body: HTTP.Body? = nil,
                                        cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
                                        timeout: TimeInterval = RequestDefaults.defaultTimeout,
                                        decoder: JSONDecoder = RequestDefaults.defaultDecoder,
                                        containerType: Container.Type) where Container.Contained == Response {
        self.init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout,
                  successTransformer: Self.successTransformer(for: decoder, with: containerType))
    }

    // MARK: - Convenience Transformers
    static func successTransformer(for decoder: JSONDecoder, errorTransformer: @escaping (Error) -> Error = { $0 }) -> Transformer {
        return { transportSuccess in
            do {
                return try decoder.decode(Response.self, from: transportSuccess.body ?? Data())
            } catch {
                throw errorTransformer(error)
            }
        }
    }

    static func successTransformer<C: DecodableContainer>(for decoder: JSONDecoder, with containerType: C.Type,
                                                          errorTransformer: @escaping (Error) -> Error = { $0 }) -> Transformer where C.Contained == Response {
        return { transportSuccess in
            do {
                return try decoder.decode(Response.self, from: transportSuccess.body ?? Data(), with: C.self)
            } catch {
                throw errorTransformer(error)
            }
        }
    }
}

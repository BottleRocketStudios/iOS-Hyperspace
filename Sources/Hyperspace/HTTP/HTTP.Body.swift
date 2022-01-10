//
//  HTTP.Body.swift
//  Hyperspace
//
//  Created by Will McGinty on 12/14/21.
//  Copyright © 2021 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public extension HTTP {

    /// Represents an HTTP request body
    struct Body: Equatable {

        /// The raw body data to be attached to the HTTP request
        public let data: Data?
        public let additionalHeaders: [HeaderKey: HeaderValue]

        /// Initializes a new `HTTP.Body` instance given the raw `Data` to be attached.
        /// - Parameters:
        ///   - data: The raw `Data` to set as the HTTP body.
        ///   - additionalHeaders: Any additional HTTP headers that should be sent with the request.
        public init(_ data: Data?, additionalHeaders: [HeaderKey: HeaderValue] = [:]) {
            self.data = data
            self.additionalHeaders = additionalHeaders
        }

        /// Returns a new `HTTP.Body` instance given an encodable object.
        /// - Parameters:
        ///   - encodable: The `Encodable` object to be included in the request.
        ///   - encoder: The `JSONEncoder` to be used to encode the object.
        ///   - additionalHeaders: Any additional HTTP headers that should be sent with the request.
        /// - Returns: A new instance of `HTTP.Body` with the given encodable representation.
        public static func json<E: Encodable>(_ encodable: E, encoder: JSONEncoder = JSONEncoder(),
                                              additionalHeaders: [HeaderKey: HeaderValue] = [.contentType: .applicationJSON]) throws -> HTTP.Body {
            let data = try encoder.encode(encodable)
            return HTTP.Body(data, additionalHeaders: additionalHeaders)
        }

        /// Returns a new `HTTP.Body` instance given an encodable object.
        /// - Parameters:
        ///   - encodable: The `Encodable` object to be included in the request.
        ///   - container: A type of `EncodableContainer` in which to encode the object.
        ///   - encoder: The `JSONEncoder` to be used to encode the object.
        ///   - additionalHeaders: Any additional HTTP headers that should be sent with the request.
        /// - Returns: A new instance of `HTTP.Body` with the given encodable representation.
        public static func json<E, C: EncodableContainer>(_ encodable: E, container: C.Type, encoder: JSONEncoder = JSONEncoder(),
                                                          additionalHeaders: [HeaderKey: HeaderValue] = [.contentType: .applicationJSON])
            throws -> HTTP.Body where C.Contained == E {
                let data = try encoder.encode(encodable, in: container)
                return HTTP.Body(data, additionalHeaders: additionalHeaders)
        }

        /// Initializes a new `HTTP.Body` instance given a set of URL form content
        /// - Parameters:
        ///   - formContent: An array of `(String, String)` representing the content to be encoded.
        ///   - additionalHeaders: Any additional HTTP headers that should be sent with the request.
        /// - Returns: A new instance of `HTTP.Body` with the given form content.
        public static func urlForm(using formContent: [(String, String)], additionalHeaders: [HeaderKey: HeaderValue] = [.contentType: .applicationFormURLEncoded]) -> HTTP.Body {
            let formURLEncoder = FormURLEncoder()
            return HTTP.Body(formURLEncoder.encode(formContent), additionalHeaders: additionalHeaders)
        }
    }
}

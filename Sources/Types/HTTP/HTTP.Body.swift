//
//  HTTP.Body.swift
//  Hyperspace
//
//  Copyright © 2021 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public extension HTTP {

    /// Represents an HTTP request body
    struct Body: Equatable, Sendable {

        // MARK: - Properties

        /// The raw body data to be attached to the HTTP request
        public let data: Data?
        public let additionalHeaders: [HeaderKey: HeaderValue]

        // MARK: - Initializer

        /// Initializes a new `HTTP.Body` instance given the raw `Data` to be attached.
        /// - Parameters:
        ///   - data: The raw `Data` to set as the HTTP body.
        ///   - additionalHeaders: Any additional HTTP headers that should be sent with the request.
        public init(_ data: Data?, additionalHeaders: [HeaderKey: HeaderValue] = [:]) {
            self.data = data
            self.additionalHeaders = additionalHeaders
        }

        // MARK: - Preset

        /// Returns a new `HTTP.Body` instance given an encodable object.
        /// - Parameters:
        ///   - encodable: The `Encodable` object to be included in the request.
        ///   - encoder: The `JSONEncoder` to be used to encode the object.
        ///   - additionalHeaders: Any additional HTTP headers that should be sent with the request.
        /// - Returns: A new instance of `HTTP.Body` with the given encodable representation.
        public static func json<E: Encodable>(_ encodable: E, encoder: JSONEncoder = JSONEncoder(),
                                              additionalHeaders: [HeaderKey: HeaderValue] = [.contentType: .applicationJSON]) throws -> Self {
            let data = try encoder.encode(encodable)
            return .init(data, additionalHeaders: additionalHeaders)
        }

        /// Returns a new `HTTP.Body` instance given an encodable object.
        /// - Parameters:
        ///   - encodable: The `Encodable` object to be included in the request.
        ///   - container: A type of `EncodableContainer` in which to encode the object.
        ///   - encoder: The `JSONEncoder` to be used to encode the object.
        ///   - additionalHeaders: Any additional HTTP headers that should be sent with the request.
        /// - Returns: A new instance of `HTTP.Body` with the given encodable representation.
        public static func json<C: EncodableContainer>(_ encodable: C.Contained, container: C.Type, encoder: JSONEncoder = JSONEncoder(),
                                                       additionalHeaders: [HeaderKey: HeaderValue] = [.contentType: .applicationJSON]) throws -> Self {
            let data = try encoder.encode(encodable, in: container)
            return .init(data, additionalHeaders: additionalHeaders)
        }
    }
}

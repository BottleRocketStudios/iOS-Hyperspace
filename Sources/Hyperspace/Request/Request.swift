//
//  Request.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

//
//  TODO: Future functionality:
//          - Extend to allow for easy handling of multipart form data upload.
//

import Foundation
import Result

/// Represents an error which can be constructed from a `NetworkServiceFailure`.
public protocol NetworkServiceFailureInitializable: Swift.Error {
    init(networkServiceFailure: NetworkServiceFailure)
    
    var networkServiceError: NetworkServiceError { get }
    var failureResponse: HTTP.Response? { get }
}

/// Represents an error which can be constructed from a `DecodingError` and `Data`.
public protocol DecodingFailureInitializable: Swift.Error {
    init(decodingError: DecodingError, data: Data)
}

@available(*, deprecated, message: "The NetworkRequest protocol has been renamed Request.")
public typealias NetworkRequest = Request

/// Encapsulates all the necessary parameters to represent a request that can be sent over the network.
public protocol Request {
    
    /// The model type that this Request will attempt to transform Data into.
    associatedtype ResponseType
    associatedtype ErrorType: NetworkServiceFailureInitializable
    
    /// The HTTP method to be use when executing this request.
    var method: HTTP.Method { get }
    
    /// The URL to use when executing this network request.
    var url: URL { get }
    
    /// The header field keys/values to use when executing this network request.
    var headers: [HTTP.HeaderKey: HTTP.HeaderValue]? { get set }
    
    /// The payload body for this network request, if any.
    var body: Data? { get set }
    
    /// The cache policy to use when executing this network request.
    var cachePolicy: URLRequest.CachePolicy { get }
    
    /// The timeout to use when executing this network request.
    var timeout: TimeInterval { get }
    
    /// The URLRequest that represents this network request.
    var urlRequest: URLRequest { get }
        
    /// Attempts to parse the provided Data into the associated response model type for this request.
    ///
    /// - Parameter data: The raw Data retrieved from the network.
    /// - Returns: A result indicating the successful or failed transformation of the data into the associated response type.
    func transformData(_ data: Data) -> Result<ResponseType, ErrorType>
}

// MARK: - EmptyResponse

/// A simple struct representing an empty server response to a request.
/// This is useful primarily for DELETE requests, in which case a "200" status with empty body is often the response.
public struct EmptyResponse {
    
    // NOTE: It would be ideal if the implicitly-generated memberwise initializer could automatically be available publicly instead of defining this manually.
    //       It may be possible someday - https://github.com/apple/swift-evolution/blob/master/proposals/0018-flexible-memberwise-initialization.md
    public init() { }
}

// MARK: - Request Defaults

@available(*, deprecated, message: "The NetworkRequestDefaults struct has been renamed RequestDefaults.")
public typealias NetworkRequestDefaults = RequestDefaults

public struct RequestDefaults {
    
    public static var defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    public static var defaultTimeout: TimeInterval = 30
    
    public typealias CatchErrorTransformer<E> = (Swift.Error, Data) -> E
    
    public static func dataTransformer<ResponseType: Decodable, ErrorType>(for decoder: JSONDecoder, catchTransformer: @escaping CatchErrorTransformer<ErrorType>) -> (Data) -> Result<ResponseType, ErrorType> {
        return { data in
            do {
                let decodedResponse: ResponseType = try decoder.decode(ResponseType.self, from: data)
                return .success(decodedResponse)
            } catch {
                return .failure(catchTransformer(error, data))
            }
        }
    }
    
    public static func dataTransformer<ResponseType: Decodable, ErrorType: DecodingFailureInitializable>(for decoder: JSONDecoder) -> (Data) -> Result<ResponseType, ErrorType> {
        return dataTransformer(for: decoder) {
            guard let decodingError = $0 as? DecodingError else { fatalError("JSONDecoder should always throw a DecodingError.") }
            return ErrorType(decodingError: decodingError, data: $1)
        }
    }
    
    public static func dataTransformer<ContainerType: DecodableContainer, ErrorType>(for decoder: JSONDecoder, withContainerType containerType: ContainerType.Type,
                                                                                     catchTransformer: @escaping CatchErrorTransformer<ErrorType>) -> (Data) -> Result<ContainerType.ContainedType, ErrorType> {
        return { data in
            do {
                
                let decodedResponse: ContainerType.ContainedType = try decoder.decode(ContainerType.ContainedType.self, from: data, with: containerType)
                return .success(decodedResponse)
            } catch {
                return .failure(catchTransformer(error, data))
            }
        }
    }
    
    public static func dataTransformer<ContainerType: DecodableContainer, ErrorType: DecodingFailureInitializable>(for decoder: JSONDecoder,
                                                                                                                   withContainerType containerType: ContainerType.Type) -> (Data) -> Result<ContainerType.ContainedType, ErrorType> {
        return dataTransformer(for: decoder, withContainerType: containerType) {
            guard let decodingError = $0 as? DecodingError else { fatalError("JSONDecoder should always throw a DecodingError.") }
            return ErrorType(decodingError: decodingError, data: $1)
        }
    }
}

// MARK: - Request Default Implementations

public extension Request {
    
    var cachePolicy: URLRequest.CachePolicy {
        return RequestDefaults.defaultCachePolicy
    }
    
    var timeout: TimeInterval {
        return RequestDefaults.defaultTimeout
    }
        
    var urlRequest: URLRequest {
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeout)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Transform the headers from [HTTP.HeaderKey: HTTP.HeaderValue] to [String: String]
        let rawHeaders: [String: String] = Dictionary(uniqueKeysWithValues: (headers ?? [:]).map { ($0.rawValue, $1.rawValue) })
        request.allHTTPHeaderFields = rawHeaders
        
        return request
    }
    
    /// Adds the specified headers to the HTTP headers already attached to the `Request`.
    ///
    /// - Parameter additionalHeaders: The HTTP headers to add to the request
    /// - Returns: A new `NetworkReqest` with the combined HTTP headers. In the case of a collision, the value from `additionalHeaders` is preferred.
    func addingHeaders(_ additionalHeaders: [HTTP.HeaderKey: HTTP.HeaderValue]) -> Self {
        let modifiedHeaders = (headers ?? [:])?.merging(additionalHeaders) { return $1 }
        return usingHeaders(modifiedHeaders)
    }
    
    /// Modifies the HTTP headers on the `Request`.
    ///
    /// - Parameter headers: The HTTP headers to add to the request.
    /// - Returns: A new `NetworkReqest` with the given HTTP headers.
    func usingHeaders(_ headers: [HTTP.HeaderKey: HTTP.HeaderValue]?) -> Self {
        var copy = self
        copy.headers = headers
        return copy
    }
    
    /// Modifies the HTTP body on the `Request`.
    ///
    /// - Parameter body: The HTTP body to add to the request.
    /// - Returns: A new `NetworkReqest` with the given HTTP body
    func usingBody(_ body: Data?) -> Self {
        var copy = self
        copy.body = body
        return copy
    }
}

// MARK: - Request Default Implementations

public extension Request where ResponseType: Decodable, ErrorType: DecodingFailureInitializable {
    
    func dataTransformer(with decoder: JSONDecoder) -> (Data) -> Result<ResponseType, ErrorType> {
        return RequestDefaults.dataTransformer(for: decoder)
    }
    
    func transformData(_ data: Data) -> Result<ResponseType, ErrorType> {
        return dataTransformer(with: JSONDecoder())(data)
    }
}

public extension Request where ResponseType == EmptyResponse {
    func transformData(_ data: Data) -> Result<EmptyResponse, ErrorType> {
        return .success(EmptyResponse())
    }
}

// MARK: - AnyError Conformance to NetworkServiceInitializable

extension AnyError: NetworkServiceFailureInitializable {

    public init(networkServiceFailure: NetworkServiceFailure) {
        self.init(networkServiceFailure.error)
    }
    
    public var networkServiceError: NetworkServiceError {
        return (error as? NetworkServiceError) ?? .unknownError
    }
    
    public var failureResponse: HTTP.Response? {
        return nil
    }
}

// MARK: - AnyError Conformance to DecodingFailureInitializable

extension AnyError: DecodingFailureInitializable {
    public init(decodingError: DecodingError, data: Data) {
        self.init(decodingError)
    }
}

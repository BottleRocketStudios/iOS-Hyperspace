//
//  Request.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents an error which can be constructed from a `NetworkServiceFailure`.
public protocol NetworkServiceFailureInitializable: Swift.Error {
    init(networkServiceFailure: NetworkServiceFailure)
    
    var networkServiceError: NetworkServiceError { get }
    var failureResponse: HTTP.Response? { get }
}

/// Represents an error which can be constructed from a `DecodingError` and `Data`.
public protocol DecodingFailureInitializable: Swift.Error {
    init(error: DecodingError, decoding: Decodable.Type, data: Data)
}

/// A block that transforms a request's `NetworkServiceSuccess` into a `Result<T,E>`.
/// This is the same signature as the `transformSuccess(_:)` method on the `Request` protocol.
public typealias RequestTransformBlock<T, E: Error> = (NetworkServiceSuccess) -> Result<T, E>

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
    /// - Parameter serviceSuccess: The successful result of executing a Request using a NetworkService.
    /// - Returns: A result indicating the successful or failed transformation of the data into the associated response type.
    func transformSuccess(_ serviceSuccess: NetworkServiceSuccess) -> Result<ResponseType, ErrorType>
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

public struct RequestDefaults {
    
    public static var defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    public static var defaultTimeout: TimeInterval = 30
    
    public typealias DecodingErrorTransformer<E> = (Swift.Error, Any.Type, Data) -> E
    
    public static func successTransformer<ResponseType: Decodable, ErrorType: DecodingFailureInitializable>(for decoder: JSONDecoder) -> RequestTransformBlock<ResponseType, ErrorType> {
        return successTransformer(for: decoder) {
            return error(from: $0, decoding: ResponseType.self, from: $2)
        }
    }
    
    public static func successTransformer<ResponseType: Decodable, ErrorType>(for decoder: JSONDecoder, catchTransformer: @escaping DecodingErrorTransformer<ErrorType>) -> RequestTransformBlock<ResponseType, ErrorType> {
        return { success in
            let data = success.data
            
            do {
                let decodedResponse: ResponseType = try decoder.decode(ResponseType.self, from: data)
                return .success(decodedResponse)
            } catch {
                return .failure(catchTransformer(error, ResponseType.self, data))
            }
        }
    }
    
    public static func successTransformer<ContainerType: DecodableContainer, ErrorType: DecodingFailureInitializable>(for decoder: JSONDecoder,
                                                                                                                      withContainerType containerType: ContainerType.Type) -> RequestTransformBlock<ContainerType.ContainedType, ErrorType> {
        return successTransformer(for: decoder, withContainerType: containerType) {
            return error(from: $0, decoding: ContainerType.self, from: $2)
        }
    }
    
    public static func successTransformer<ContainerType: DecodableContainer, ErrorType>(for decoder: JSONDecoder, withContainerType containerType: ContainerType.Type,
                                                                                        catchTransformer: @escaping DecodingErrorTransformer<ErrorType>) -> RequestTransformBlock<ContainerType.ContainedType, ErrorType> {
        return { success in
            let data = success.data
            
            do {
                
                let decodedResponse: ContainerType.ContainedType = try decoder.decode(ContainerType.ContainedType.self, from: data, with: containerType)
                return .success(decodedResponse)
            } catch {
                return .failure(catchTransformer(error, ContainerType.ContainedType.self, data))
            }
        }
    }
    
    @available(*, deprecated, renamed: "successTransformer(for:)")
    public static func dataTransformer<ResponseType: Decodable, ErrorType: DecodingFailureInitializable>(for decoder: JSONDecoder) -> RequestTransformBlock<ResponseType, ErrorType> {
        return successTransformer(for: decoder)
    }

    @available(*, deprecated, renamed: "successTransformer(for:catchTransformer:)")
    public static func dataTransformer<ResponseType: Decodable, ErrorType>(for decoder: JSONDecoder, catchTransformer: @escaping DecodingErrorTransformer<ErrorType>) -> RequestTransformBlock<ResponseType, ErrorType> {
        return successTransformer(for: decoder, catchTransformer: catchTransformer)
    }
    
    @available(*, deprecated, renamed: "successTransformer(for:withContainerType:)")
    public static func dataTransformer<ContainerType: DecodableContainer, ErrorType: DecodingFailureInitializable>(for decoder: JSONDecoder,
                                                                                                                   withContainerType containerType: ContainerType.Type) -> RequestTransformBlock<ContainerType.ContainedType, ErrorType> {
        return successTransformer(for: decoder, withContainerType: containerType)
    }
    
    @available(*, deprecated, renamed: "successTransformer(for:withContainerType:catchTransformer:)")
    public static func dataTransformer<ContainerType: DecodableContainer, ErrorType>(for decoder: JSONDecoder, withContainerType containerType: ContainerType.Type,
                                                                                     catchTransformer: @escaping DecodingErrorTransformer<ErrorType>) -> RequestTransformBlock<ContainerType.ContainedType, ErrorType> {
        return successTransformer(for: decoder, withContainerType: containerType, catchTransformer: catchTransformer)
    }
    
    private static func error<ErrorType: DecodingFailureInitializable>(from error: Swift.Error, decoding type: Decodable.Type, from data: Data) -> ErrorType {
        guard let decodingError = error as? DecodingError else { fatalError("JSONDecoder should always throw a DecodingError.") }
        return ErrorType(error: decodingError, decoding: type, data: data)
    }
}

// MARK: - Request Default Implementations

public extension Request {

    var queryParameters: [URLQueryItem]? {
        return nil
    }
    
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

// MARK: - Request Default Implementations [Codable]

public extension Request where ResponseType: Decodable, ErrorType: DecodingFailureInitializable {
    
    func dataTransformer(with decoder: JSONDecoder) -> RequestTransformBlock<ResponseType, ErrorType> {
        return RequestDefaults.successTransformer(for: decoder)
    }
    
    func transformSuccess(_ serviceSuccess: NetworkServiceSuccess) -> Result<ResponseType, ErrorType> {
        return dataTransformer(with: JSONDecoder())(serviceSuccess)
    }
}

// MARK: - Request Default Implementations [EmptyResponse]

public extension Request where ResponseType == EmptyResponse {
    
    func transformSuccess(_ serviceSuccess: NetworkServiceSuccess) -> Result<EmptyResponse, ErrorType> {
        return .success(EmptyResponse())
    }
}

//
//  NetworkRequest.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

//
//  TODO: Future functionality:
//          - Extend to allow for easy handling of multipart form data upload.
//          - Add support for providing a root key to parse the response from (for the NetworkRequest extension dealing with a 'ResponseType' that's 'Decodable').
//

import Foundation
import Result

/// Represents the strategy used to encode query parameters in the URL.
// swiftlint:disable type_name
public enum NetworkRequestQueryParameterEncodingStrategy {
    public typealias QueryStringEncodingBlock = (String) -> String
    
    case urlQueryAllowedCharacterSet
    case custom(QueryStringEncodingBlock)
    
    func encode(string: String) -> String {
        switch self {
        case .urlQueryAllowedCharacterSet:
            guard let encodedQueryString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { fatalError("Unable to encode query parameters for \(self)") }
            return encodedQueryString
        case .custom(let encodingBlock):
            return encodingBlock(string)
        }
    }
}
// swiftlint:enable type_name

/// Encapsulates all the necessary parameters to represent a request that can be sent over the network.
public protocol NetworkRequest {
    
    /// The model type that this NetworkRequest will attempt to transform Data into.
    associatedtype ResponseType
    associatedtype ErrorType: Swift.Error
    
    /// The HTTP method to be use when executing this request.
    var method: HTTP.Method { get }
    
    /// The URL to use when executing this network request.
    var url: URL { get }
    
    /// The query parameters to use when executing this network request.
    var queryParameters: [URLQueryItem]? { get }
    
    /// The encoding strategy to use when encoding the raw query parameter string before generating the final URL used to execute the request against.
    var queryParameterEncodingStrategy: NetworkRequestQueryParameterEncodingStrategy { get }
    
    /// The header field keys/values to use when executing this network request.
    var headers: [HTTP.HeaderKey: HTTP.HeaderValue]? { get }
    
    /// The payload body for this network request, if any.
    var body: Data? { get }
    
    /// The cache policy to use when executing this network request.
    var cachePolicy: URLRequest.CachePolicy { get }
    
    /// The timeout to use when executing this network request.
    var timeout: TimeInterval { get }
    
    /// The URLRequest that represents this network request.
    var urlRequest: URLRequest { get }
    
    /// Generates a raw query string from the provided query parameters. Does not include the '?' prefix.
    ///
    /// - Parameter queryParameters: The query parameter key-value pairs.
    /// - Returns: A string representing the unencoded concatination of each key-value pair.
    func generateRawQueryParameterString(from queryParameters: [URLQueryItem]) -> String
    
    /// Attempts to parse the provided Data into the associated response model type for this request.
    ///
    /// - Parameter data: The raw Data retrieved from the network.
    /// - Returns: A result indicating the successful or failed transformation of the data into the associated response type.
    func transformData(_ data: Data) -> Result<ResponseType, ErrorType>
}

/// A simple struct representing an empty server response to a request.
/// This is useful primarily for DELETE requests, in which case a "200" status with empty body is often the response.
public struct EmptyResponse {
    
    // NOTE: It would be ideal if the implicitly-generated memberwise initializer could automatically be available publicly instead of defining this manually.
    //       It may be possible someday - https://github.com/apple/swift-evolution/blob/master/proposals/0018-flexible-memberwise-initialization.md
    public init() { }
}

// MARK: - NetworkRequest Default Implementations

public struct NetworkRequestDefaults {
    
    public static var defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    public static var defaultTimeout: TimeInterval = 30
    
    public static var defaultQueryParameterEncodingStrategy: NetworkRequestQueryParameterEncodingStrategy = .urlQueryAllowedCharacterSet
    
    public static func dataTransformer<T: Decodable>(for decoder: JSONDecoder) -> (Data) -> Result<T, AnyError> {
        return { data in
            do {
                let decodedResponse: T = try decoder.decode(T.self, from: data)
                return .success(decodedResponse)
            } catch {
                return .failure(AnyError(error))
            }
        }
    }
}

public extension NetworkRequest {
    
    var cachePolicy: URLRequest.CachePolicy {
        return NetworkRequestDefaults.defaultCachePolicy
    }
    
    var timeout: TimeInterval {
        return NetworkRequestDefaults.defaultTimeout
    }
    
    var queryParameterEncodingStrategy: NetworkRequestQueryParameterEncodingStrategy {
        return NetworkRequestDefaults.defaultQueryParameterEncodingStrategy
    }
    
    var urlRequest: URLRequest {
        let rawQueryString = generateRawQueryParameterString(from: queryParameters ?? [])
        let encodedQueryString = queryParameterEncodingStrategy.encode(string: rawQueryString)
        
        let requestURL = url.appendingQueryString(encodedQueryString)
        
        var request = URLRequest(url: requestURL, cachePolicy: cachePolicy, timeoutInterval: timeout)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Transform the headers from [HTTP.HeaderKey: HTTP.HeaderValue] to [String: String]
        let rawHeaders: [String: String] = Dictionary(uniqueKeysWithValues: (headers ?? [:]).map { ($0.rawValue, $1.rawValue) })
        request.allHTTPHeaderFields = rawHeaders
        
        return request
    }
    
    func generateRawQueryParameterString(from queryParameters: [URLQueryItem]) -> String {
        return URLQueryItem.generateRawQueryParametersString(from: queryParameters)
    }
    
    func encodeQueryParameterString(_ queryString: String) -> String {
        return queryParameterEncodingStrategy.encode(string: queryString)
    }
}

public extension NetworkRequest where ResponseType: Decodable, ErrorType == AnyError {
    
    func dataTransformer(with decoder: JSONDecoder) -> (Data) -> Result<ResponseType, ErrorType> {
        return NetworkRequestDefaults.dataTransformer(for: decoder)
    }
    
    func transformData(_ data: Data) -> Result<ResponseType, ErrorType> {
        return dataTransformer(with: JSONDecoder())(data)
    }
}

public extension NetworkRequest where ResponseType == EmptyResponse {
    func transformData(_ data: Data) -> Result<EmptyResponse, ErrorType> {
        return .success(EmptyResponse())
    }
}

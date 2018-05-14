//
//  AnyNetworkRequest+DecodableContainerType.swift
//  Hyperspace
//
//  Created by Will McGinty on 11/27/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Result

/// Represents something that is capable of Decoding itself (using Swift.Decodable) and contains a child type.
public protocol DecodableContainer: Decodable {
    
    /// The type of the Swift.Decodable child element.
    associatedtype ContainedType: Decodable
    
    /// Retrieve the child type from its container.
    var element: ContainedType { get }
}

extension AnyNetworkRequest where T: Decodable {
    
    public init<U: DecodableContainer>(method: HTTP.Method,
                                       url: URL,
                                       headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                                       body: Data? = nil,
                                       cachePolicy: URLRequest.CachePolicy = NetworkRequestDefaults.defaultCachePolicy,
                                       timeout: TimeInterval = NetworkRequestDefaults.defaultTimeout,
                                       decoder: JSONDecoder = JSONDecoder(),
                                       containerType: U.Type) where U.ContainedType == T {
        self.init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout) { data in
            do {
                let container = try decoder.decode(U.self, from: data)
                return .success(container.element)
            } catch {
                return .failure(AnyError(error))
            }
        }
    }
    
    public init(method: HTTP.Method,
                url: URL,
                headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                body: Data? = nil,
                cachePolicy: URLRequest.CachePolicy = NetworkRequestDefaults.defaultCachePolicy,
                timeout: TimeInterval = NetworkRequestDefaults.defaultTimeout,
                decoder: JSONDecoder = JSONDecoder(),
                rootDecodingKey: String) {
        self.init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout) { data in
            do {
                
                //TODO: This logic could be extracted to accomodate a [String] of keys, but would incur additional performance costs (due to re-serialization).
                
                let container = try decoder.decode([String: AnyDecodable].self, from: data)
                guard let element = container[rootDecodingKey] else {
                    let context = DecodingError.Context(codingPath: [],
                                                        debugDescription: "No value found at root key \"\(rootDecodingKey)\".")
                    throw DecodingError.valueNotFound(T.self, context)
                }

                let data = try JSONSerialization.data(withJSONObject: element.value, options: [])
                let decodedElement = try decoder.decode(T.self, from: data)
                return .success(decodedElement)

            } catch {
                return .failure(AnyError(error))
            }
        }
    }
}

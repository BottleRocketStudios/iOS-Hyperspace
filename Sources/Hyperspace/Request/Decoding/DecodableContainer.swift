//
//  DecodableContainer.swift
//  Hyperspace
//
//  Created by Will McGinty on 11/27/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents something that is capable of Decoding itself (using Swift.Decodable) and contains a child type.
public protocol DecodableContainer: Decodable {
    
    /// The type of the Swift.Decodable child element.
    associatedtype ContainedType: Decodable
    
    /// Retrieve the child type from its container.
    var element: ContainedType { get }
}

// MARK: - AnyRequest Default Implementations

extension AnyRequest where T: Decodable {
    
    public init<U: DecodableContainer>(method: HTTP.Method,
                                       url: URL,
                                       headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                                       body: Data? = nil,
                                       cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
                                       timeout: TimeInterval = RequestDefaults.defaultTimeout,
                                       decoder: JSONDecoder = JSONDecoder(),
                                       containerType: U.Type) where U.ContainedType == T {
        self.init(method: method, url: url, headers: headers, body: body, cachePolicy: cachePolicy, timeout: timeout, dataTransformer: RequestDefaults.successTransformer(for: decoder, withContainerType: containerType))
    }
}

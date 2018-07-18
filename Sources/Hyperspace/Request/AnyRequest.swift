//
//  AnyRequest.swift
//  Hyperspace
//
//  Created by Will McGinty on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Result

/// A type-erased structure to allow for simple Requests to be easily created.
public struct AnyRequest<T>: Request {
    
    // MARK: - Properties
    
    public var method: HTTP.Method
    public var url: URL
    public var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
    public var body: Data?
    public var cachePolicy: URLRequest.CachePolicy
    public var timeout: TimeInterval
    private let _transformData: (Data) -> Result<T, AnyError>
    
    // MARK: - Init
    
    public init(method: HTTP.Method,
                url: URL,
                headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                body: Data? = nil,
                cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
                timeout: TimeInterval = RequestDefaults.defaultTimeout,
                dataTransformer: @escaping (Data) -> Result<T, AnyError>) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
        self.timeout = timeout
        
        _transformData = dataTransformer
    }
    
    // MARK: - Public
    
    public func transformData(_ data: Data) -> Result<T, AnyError> {
        return _transformData(data)
    }
}

// MARK: - AnyRequest Default Implementations

extension AnyRequest where T: Decodable {
    
    public init(method: HTTP.Method,
                url: URL,
                headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                body: Data? = nil,
                cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
                timeout: TimeInterval = RequestDefaults.defaultTimeout,
                decoder: JSONDecoder = JSONDecoder()) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
        self.timeout = timeout
        
        _transformData = RequestDefaults.dataTransformer(for: decoder)
    }
}

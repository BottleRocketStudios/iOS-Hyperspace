//
//  TransportResult.swift
//  Hyperspace-iOS
//
//  Created by William McGinty on 3/6/20.
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents an error that occurred when executing a `Request` using a `TransportService`.
public struct TransportError: Error, Equatable {
    
    // MARK: - Code Subtype
    
    public enum Code: Equatable {
        case clientError(HTTP.Status.ClientError)
        case serverError(HTTP.Status.ServerError)
        case cancelled
        case noInternetConnection
        case timedOut
        case redirection
        case other(URLError)
        case unknownError
        
        // MARK: - Initializer
        
        public init(clientError: Error?) {
            self = (clientError as? URLError).flatMap {
                switch $0.code {
                case .cancelled: return .cancelled
                case .notConnectedToInternet: return .noInternetConnection
                case .timedOut: return .timedOut
                default: return .other($0)
                }
            } ?? .unknownError
        }
    }
    
    // MARK: - Properties
    
    public let code: Code
    public let failingURL: URL?
    
    // MARK: - Initializers
    
    public init(code: Code, failingURL: URL? = nil) {
        self.code = code
        self.failingURL = failingURL
    }
    
    public init(clientError: Error?) {
        let urlError = clientError as? URLError
        self.init(code: Code(clientError: clientError), failingURL: urlError?.failingURL)
    }
}

/// Represents the successful result of executing a `Request` using a `TransportService`.

@available(*, renamed: "TransportSuccess")
public typealias NetworkServiceSuccess = TransportSuccess

public struct TransportSuccess: Equatable {
    public let response: HTTP.Response
    public var data: Data { return response.data ?? Data() }
    
    public init(response: HTTP.Response) {
        self.response = response
    }
}

@available(*, renamed: "TransportFailure")
public typealias NetworkServiceFailure = TransportFailure

/// Represents the failed result of executing a `Request` using a `TransportService`.
public struct TransportFailure: Error, Equatable {
    public let error: TransportError
    public let response: HTTP.Response?
    
    public init(error: TransportError, response: HTTP.Response?) {
        self.error = error
        self.response = response
    }
    
    public init(code: TransportError.Code, response: HTTP.Response?) {
        self.init(error: TransportError(code: code, failingURL: response?.url), response: response)
    }
}

// MARK: - HTTP.Response + TransportResult

public extension HTTP.Response {
    
    var transportResult: TransportResult {
        switch status {
        case .success: return .success(TransportSuccess(response: self))
        case .redirection: return .failure(TransportFailure(error: TransportError(code: .redirection, failingURL: url), response: self))
        case .clientError(let clientError): return .failure(TransportFailure(error: TransportError(code: .clientError(clientError), failingURL: url), response: self))
        case .serverError(let serverError): return .failure(TransportFailure(error: TransportError(code: .serverError(serverError), failingURL: url), response: self))
        case .unknown: return .failure(TransportFailure(error: TransportError(code: .unknownError, failingURL: url), response: self))
        }
    }
}

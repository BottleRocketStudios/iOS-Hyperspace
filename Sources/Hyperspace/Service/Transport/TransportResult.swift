//
//  TransportResult.swift
//  Hyperspace-iOS
//
//  Created by William McGinty on 3/6/20.
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents an error which can be constructed from a `TransportFailure`.
public protocol TransportFailureRepresentable: Swift.Error {

    init(transportFailure: TransportFailure)

    var failureResponse: HTTP.Response? { get }
    var transportError: TransportError? { get }
}

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
    public let underlyingError: Error?

    // MARK: - Initializers
    
    public init(code: Code, underlyingError: Error? = nil) {
        self.code = code
        self.underlyingError = underlyingError
    }
    
    public init(clientError: Error?) {
        self.init(code: Code(clientError: clientError), underlyingError: clientError)
    }

    // MARK: - Equatable
    public static func == (lhs: TransportError, rhs: TransportError) -> Bool {
        return lhs.code == rhs.code
    }
}

/// Represents the successful result of executing a `Request` using a `TransportService`.

@available(*, renamed: "TransportSuccess")
public typealias NetworkServiceSuccess = TransportSuccess

public struct TransportSuccess: Equatable {

    // MARK: - Properties

    public let response: HTTP.Response

    public var body: Data? { return response.body }
    public var request: HTTP.Request { return response.request }

    // MARK: - Initializer

    public init(response: HTTP.Response) {
        self.response = response
    }
}

@available(*, renamed: "TransportFailure")
public typealias NetworkServiceFailure = TransportFailure

/// Represents the failed result of executing a `Request` using a `TransportService`.
public struct TransportFailure: Error, Equatable {

    // MARK: - Properties

    public let error: TransportError
    public let request: HTTP.Request
    public let response: HTTP.Response?

    // MARK: - Initializers
    
    public init(error: TransportError, request: HTTP.Request, response: HTTP.Response?) {
        self.error = error
        self.request = request
        self.response = response
    }

    public init(code: TransportError.Code, request: HTTP.Request, response: HTTP.Response?) {
        self.init(error: TransportError(code: code), request: request, response: response)
    }

    public init(code: TransportError.Code, response: HTTP.Response) {
        self.init(code: code, request: response.request, response: response)
    }

    public init(error: TransportError, response: HTTP.Response) {
        self.init(error: error, request: response.request, response: response)
    }
}

// MARK: - HTTP.Response + TransportResult

public extension HTTP.Response {
    
    var transportResult: TransportResult {
        switch status {
        case .success: return .success(TransportSuccess(response: self))
        case .redirection: return .failure(TransportFailure(error: TransportError(code: .redirection), response: self))
        case .clientError(let clientError): return .failure(TransportFailure(error: TransportError(code: .clientError(clientError)), response: self))
        case .serverError(let serverError): return .failure(TransportFailure(error: TransportError(code: .serverError(serverError)), response: self))
        case .unknown: return .failure(TransportFailure(error: TransportError(code: .unknownError), response: self))
        }
    }
}

//
//  TransportResult.swift
//  Hyperspace
//
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents the successful result of executing a `Request` using a `TransportService`.
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

/// Represents the failed result of executing a `Request` using a `TransportService`.
public struct TransportFailure: Error, Equatable {

    // MARK: - Kind Subtype
    public enum Kind: Equatable {
        case redirection
        case clientError(HTTP.Status.ClientError)
        case serverError(HTTP.Status.ServerError)
        case unknown
    }

    // MARK: - Properties
    public let kind: Kind
    public let request: HTTP.Request
    public let response: HTTP.Response?

    // MARK: - Initializers
    public init(kind: Kind, request: HTTP.Request, response: HTTP.Response? = nil) {
        self.kind = kind
        self.request = request
        self.response = response
    }

    public init(kind: Kind, response: HTTP.Response) {
        self.init(kind: kind, request: response.request, response: response)
    }
}

// MARK: - TransportResult

/// Represents the possible resulting values of a `Request` using a `TransportService`.
public typealias TransportResult = Result<TransportSuccess, TransportFailure>

public extension TransportResult {

    var request: HTTP.Request {
        switch self {
        case .success(let success): return success.request
        case .failure(let failure): return failure.request
        }
    }

    var response: HTTP.Response? {
        switch self {
        case .success(let success): return success.response
        case .failure(let failure): return failure.response
        }
    }
}

// MARK: - HTTP.Response + TransportResult
public extension HTTP.Response {
    
    var transportResult: TransportResult {
        switch status {
        case .success: return .success(TransportSuccess(response: self))
        case .redirection: return .failure(TransportFailure(kind: .redirection, response: self))
        case .clientError(let clientError): return .failure(TransportFailure(kind: .clientError(clientError), response: self))
        case .serverError(let serverError): return .failure(TransportFailure(kind: .serverError(serverError), response: self))
        case .unknown: return .failure(TransportFailure(kind: .unknown, response: self))
        }
    }
}

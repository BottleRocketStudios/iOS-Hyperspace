//
//  NetworkServiceProtocol.swift
//  Hyperspace
//
//  Created by Tyler Milner on 7/10/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

//
//  TODO: Future functionality:
//          - Look into providing a protocol that allows clients to custom interpret URLResponses (HTTP status codes).
//          - Look into providing the raw URLResponse as a property on NetworkServiceSuccess/FailureResult so that clients have access to the raw response object.
//            One caveat is the fact that HTTPURLResponse and URLResponse don't currently properly handle Equatable so we'll need to figure out how we want to handle this.
//

import Foundation
import Result

/// Represents an error that occurred when executing a NetworkRequest using a NetworkService.
public enum NetworkServiceError: Error {
    case unknownError
    case unknownStatusCode
    case redirection
    case clientError(HTTP.Status.ClientError)
    case serverError(HTTP.Status.ServerError)
    case noData
    case noInternetConnection
    case timedOut
    case cancelled
}

/// Represents the successful result of executing a NetworkRequest using a NetworkService.
public struct NetworkServiceSuccess {
    let data: Data
    let response: HTTP.Response
}

/// Represents the failed result of executing a NetworkRequest using a NetworkService.
public struct NetworkServiceFailure: Error {
    let error: NetworkServiceError
    let response: HTTP.Response?
}

/// Represents the possible resulting values of a NetworkRequest using a NetworkService.
public typealias NetworkServiceResult = Result<NetworkServiceSuccess, NetworkServiceFailure>

/// Upon completion of executing a NetworkRequest using a NetworkService, the NetworkServiceResult is returned.
public typealias NetworkServiceCompletion = (Result<NetworkServiceSuccess, NetworkServiceFailure>) -> Void

/// Represents something that can execute a URLRequest.
public protocol NetworkServiceProtocol {
    
    /// Executes the URLRequest, calling the provided completion block when complete.
    ///
    /// - Parameters:
    ///   - request: The URLRequest to execute.
    ///   - completion: The completion block to be invoked when request execution is complete.
    func execute(request: URLRequest, completion: @escaping NetworkServiceCompletion)
    
    /// Cancels the task for the given request (if it is currently running).
    func cancelTask(for request: URLRequest)

    /// Cancels all currently running tasks
    func cancelAllTasks()
}

extension NetworkServiceProtocol {
    
    func invalidHTTPResponseError(for error: Error?) -> NetworkServiceError {
        let networkError: NetworkServiceError = (error as NSError?).flatMap {
            switch ($0.domain, $0.code) {
            case (NSURLErrorDomain, NSURLErrorNotConnectedToInternet):
                return .noInternetConnection
            case (NSURLErrorDomain, NSURLErrorTimedOut):
                return .timedOut
            case (NSURLErrorDomain, NSURLErrorCancelled):
                return .cancelled
            default:
                return .unknownError
            }
            } ?? .unknownError
        
        return networkError
    }
}

// MARK: - Equatable Implementations

extension NetworkServiceError: Equatable {
    public static func == (lhs: NetworkServiceError, rhs: NetworkServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.unknownError, .unknownError):
            return true
        case (.unknownStatusCode, .unknownStatusCode):
            return true
        case (.redirection, .redirection):
            return true
        case (.clientError(let lhsError), .clientError(let rhsError)):
            return lhsError == rhsError
        case (.serverError(let lhsError), .serverError(let rhsError)):
            return lhsError == rhsError
        case (.noData, .noData):
            return true
        case (.noInternetConnection, .noInternetConnection):
            return true
        case (.timedOut, .timedOut):
            return true
        case (.cancelled, .cancelled):
            return true
        default:
            return false
        }
    }
}

extension NetworkServiceSuccess: Equatable {
    public static func == (lhs: NetworkServiceSuccess, rhs: NetworkServiceSuccess) -> Bool {
        return lhs.data == rhs.data && lhs.response == rhs.response
    }
}

extension NetworkServiceFailure: Equatable {
    public static func == (lhs: NetworkServiceFailure, rhs: NetworkServiceFailure) -> Bool {
        return lhs.error == rhs.error && lhs.response == rhs.response
    }
}

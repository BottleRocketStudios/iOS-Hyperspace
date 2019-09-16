//
//  NetworkServiceProtocol.swift
//  Hyperspace
//
//  Created by Tyler Milner on 7/10/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

//
//  TODO: Future functionality:
//          - Look into providing the raw URLResponse as a property on NetworkServiceSuccess/FailureResult so that clients have access to the raw response object.
//            One caveat is the fact that HTTPURLResponse and URLResponse don't currently properly handle Equatable so we'll need to figure out how we want to handle this.
//

import Foundation

/// Represents an error that occurred when executing a Request using a NetworkService.
public enum NetworkServiceError: Error {
    case unknownError(Error?)
    case unknownStatusCode
    case redirection
    case clientError(HTTP.Status.ClientError)
    case serverError(HTTP.Status.ServerError)
    case noData
    case noInternetConnection
    case timedOut
    case cancelled
}

/// Represents the successful result of executing a Request using a NetworkService.
public struct NetworkServiceSuccess: Equatable {
    public let data: Data
    public let response: HTTP.Response
    
    public init(data: Data, response: HTTP.Response) {
        self.data = data
        self.response = response
    }
}

/// Represents the failed result of executing a Request using a NetworkService.
public struct NetworkServiceFailure: Error, Equatable {
    public let error: NetworkServiceError
    public let response: HTTP.Response?
    
    public init(error: NetworkServiceError, response: HTTP.Response?) {
        self.error = error
        self.response = response
    }
}

/// Represents the possible resulting values of a Request using a NetworkService.
public typealias NetworkServiceResult = Result<NetworkServiceSuccess, NetworkServiceFailure>

/// Upon completion of executing a Request using a NetworkService, the NetworkServiceResult is returned.
public typealias NetworkServiceCompletion = (NetworkServiceResult) -> Void

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

// MARK: - Equatable Implementations

extension NetworkServiceError: Equatable {
    
    public static func == (lhs: NetworkServiceError, rhs: NetworkServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.unknownError(let lhsError), .unknownError(let rhsError)):
            return lhsError?.localizedDescription == rhsError?.localizedDescription
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

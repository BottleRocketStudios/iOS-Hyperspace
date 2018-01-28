//
//  BackendServiceProtocol.swift
//  Hyperspace
//
//  Created by Tyler Milner on 7/10/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Result

/// Represents an error that a BackendService can produce.
///
/// - networkError: Represents an error that ocurred with the underlying NetworkService.
/// - dataTransformationError: Represents an error that ocurred when parsing the raw Data into the associated model type.
public enum BackendServiceError: Error {
    case networkError(NetworkServiceError, HTTP.Response?)
    case dataTransformationError(Error)
}

/// Represents an error that can be created from a BackendServiceError. This type can be used for strongly typed error handling.
public protocol BackendServiceErrorInitializable: Error {
    init(_ backendServiceError: BackendServiceError)
}

/// Represents the completion of a request executed using a BackendService.
/// When successful, the parsed object is provided as the associated value.
/// When request execution fails, the relevant BackendServiceError is provided as the associated value.
public typealias BackendServiceCompletion<T> = (Result<T, BackendServiceError>) -> Void

/// Represents the completion of a request executed using a BackendService.
/// When successful, the parsed object is provided as the associated value.
/// When request execution fails, the relevant E is provided as the associated value.
public typealias TypedBackendServiceCompletion<T, E: Swift.Error> = (Result<T, E>) -> Void

/// Represents something that's capable of executing a typed NetworkRequest
public protocol BackendServiceProtocol {
    
    /// Executes the NetworkRequest, calling the provided completion block when finished.
    ///
    /// - Parameters:
    ///   - request: The NetworkRequest to be executed.
    ///   - completion: The completion block to invoke when execution has finished.
    func execute<T: NetworkRequest>(request: T, completion: @escaping BackendServiceCompletion<T.ResponseType>)
    
    /// Executes the NetworkRequest, calling the provided typed error completion block when finished.
    ///
    /// - Parameters:
    ///   - request: The NetworkRequest to be executed.
    ///   - completion: The completion block (with a specifcally typed error) to invoke when execution has finished.
    func execute<T: NetworkRequest, E: BackendServiceErrorInitializable>(request: T, completion: @escaping TypedBackendServiceCompletion<T.ResponseType, E>) where T.ErrorType == E
    
    /// Cancels the task for the given request (if it is currently running).
    func cancelTask(for request: URLRequest)
}

// MARK: - Default Typed Implementation

extension BackendServiceProtocol {
    public func execute<T: NetworkRequest, E: BackendServiceErrorInitializable>(request: T, completion: @escaping TypedBackendServiceCompletion<T.ResponseType, E>) where T.ErrorType == E {
        execute(request: request) { (result: Result<T.ResponseType, BackendServiceError>) in
            completion(result.flatMapError { .failure(E($0)) })
        }
    }
}

// MARK: - Equatable Implementations

extension BackendServiceError: Equatable {
    public static func == (lhs: BackendServiceError, rhs: BackendServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let lhsError, let lhsResponse), .networkError(let rhsError, let rhsResponse)):
            return lhsError == rhsError && lhsResponse == rhsResponse
        case (.dataTransformationError(let lhsError), .dataTransformationError(let rhsError)):
            // TODO: Need to come up with a better way to compare equality in this case
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - AnyError Conformance to BackendServiceErrorInitializable

extension AnyError: BackendServiceErrorInitializable {
    public init(_ backendServiceError: BackendServiceError) {
        self.init(backendServiceError)
    }
}

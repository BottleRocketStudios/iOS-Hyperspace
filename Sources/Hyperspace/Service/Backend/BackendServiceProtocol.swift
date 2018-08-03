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
@available(*, deprecated, message: "Utilize Request.ErrorType to initialize a custom error type instead.")
public enum BackendServiceError: Error {
    case networkError(NetworkServiceError, HTTP.Response?)
    case dataTransformationError(Error)
}

/// Represents an error that can be created from a BackendServiceError. This type can be used for strongly typed error handling.
@available(*, deprecated, message: "Utilize Request.ErrorType to initialize a custom error type instead.")
public protocol BackendServiceErrorInitializable: Error {
    init(_ backendServiceError: BackendServiceError)
}

/// Represents the completion of a request executed using a BackendService.
/// When successful, the parsed object is provided as the associated value.
/// When request execution fails, the relevant E is provided as the associated value.
public typealias BackendServiceCompletion<T, E: Swift.Error> = (Result<T, E>) -> Void

/// Represents something that's capable of executing a typed Request
public protocol BackendServiceProtocol {
    
    /// Executes the Request, calling the provided completion block when finished.
    ///
    /// - Parameters:
    ///   - request: The Request to be executed.
    ///   - completion: The completion block to invoke when execution has finished.
    func execute<T: Request>(request: T, completion: @escaping BackendServiceCompletion<T.ResponseType, T.ErrorType>)
    
    /// Cancels the task for the given request (if it is currently running).
    func cancelTask(for request: URLRequest)
    
    /// Cancels all currently running tasks
    func cancelAllTasks()
}

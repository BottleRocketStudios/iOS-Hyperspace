//
//  BackendServiceProtocol.swift
//  Hyperspace
//
//  Created by Tyler Milner on 7/10/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents the completion of a request executed using a BackendService.
/// When successful, the parsed object is provided as the associated value.
/// When request execution fails, the relevant E is provided as the associated value.
public typealias BackendServiceCompletion<T, E: Swift.Error> = (Result<T, E>) -> Void

/// Represents something that's capable of executing a typed Request
public protocol BackendServiceProtocol {
    /// Executes the Request, calling the provided completion block when finished.
    ///
    /// - Parameters:
    ///   - request: The `Request` to be executed.
    ///   - completion: The completion block to invoke when execution has finished.
    func execute<T: Request>(request: T, completion: @escaping BackendServiceCompletion<T.ResponseType, T.ErrorType>)
    
    
    /// Executes the request, attempting to recover if a network error occurs according to the request's recovery strategy and then calling the provided completion block when finished.
    /// - Parameters:
    ///   - request: The `Request` to be executed, which includes recovery logic should a network error occur.
    ///   - completion: The completion block to invoke when execution has finished and any recovery logic has run.
    func execute<T: Request & Recoverable>(recoverable request: T, completion: @escaping BackendServiceCompletion<T.ResponseType, T.ErrorType>)
    
    /// Cancels the task for the given request (if it is currently running).
    func cancelTask(for request: URLRequest)
    
    /// Cancels all currently running tasks
    func cancelAllTasks()
}

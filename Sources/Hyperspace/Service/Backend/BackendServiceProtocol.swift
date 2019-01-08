//
//  BackendServiceProtocol.swift
//  Hyperspace
//
//  Created by Tyler Milner on 7/10/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import BrightFutures
import Foundation
import Result

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
    
    /// Executes the Request, returning a Future when finished.
    ///
    /// - Parameters:
    ///   - request: The Request to be executed.
    /// - Returns: A Future<T.ResponseType> that resolves to the request's response type.
    func execute<T: Request>(request: T) -> Future<T.ResponseType, T.ErrorType>
    
    /// Cancels the task for the given request (if it is currently running).
    func cancelTask(for request: URLRequest)
    
    /// Cancels all currently running tasks
    func cancelAllTasks()
}

extension BackendServiceProtocol {
    public func execute<T: Request>(request: T) -> Future<T.ResponseType, T.ErrorType> {
        let promise = Promise<T.ResponseType, T.ErrorType>()
        
        execute(request: request) { result in
            promise.complete(result)
        }
        
        return promise.future
    }
}

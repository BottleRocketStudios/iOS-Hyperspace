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
public protocol BackendServiceProtocol: AnyObject {

    /// Determines how the backend service should recover from errors, should the request be able to do so. If this object is not present, all errors are returned to the client.
    var recoveryStrategy: RequestRecoveryStrategy? { get }

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

// MARK: - BackendServiceProtocol Default Implementations

public extension BackendServiceProtocol {

    var recoveryStrategy: RequestRecoveryStrategy? { return nil }

    func execute<T: Request & Recoverable>(recoverable request: T, completion: @escaping BackendServiceCompletion<T.ResponseType, T.ErrorType>) {
        execute(request: request) { [weak self] result in
            switch result {
            case .success(let response):
                BackendServiceHelper.handleResponse(response, completion: completion)

            case .failure(let error):
                guard let recoveryStrategy = self?.recoveryStrategy else {
                    return BackendServiceHelper.handleErrorFailure(error, completion: completion)
                }

                recoveryStrategy.handleRecoveryAttempt(for: request, withError: error) { recoveryDisposition in
                    switch recoveryDisposition {
                    case .fail:
                        BackendServiceHelper.handleErrorFailure(error, completion: completion)
                    case .retry(let recoveredRequest):
                        self?.execute(recoverable: recoveredRequest, completion: completion)
                    }
                }
            }
        }
    }
}

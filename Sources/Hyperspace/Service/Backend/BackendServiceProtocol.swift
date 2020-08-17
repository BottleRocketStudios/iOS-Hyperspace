//
//  BackendServiceProtocol.swift
//  Hyperspace
//
//  Created by Tyler Milner on 7/10/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents an error which can be constructed from a `TransportFailure`.
public protocol TransportFailureRepresentable: Swift.Error {
    
    init(transportFailure: TransportFailure)
    
    var failureResponse: HTTP.Response? { get }
    var transportError: TransportError? { get }
}

/// Represents an error which can be constructed from a `DecodingError` and `Data`.
public protocol DecodingFailureRepresentable: TransportFailureRepresentable {
    init(error: DecodingError, decoding: Decodable.Type, response: HTTP.Response)
}

/// Represents something that's capable of executing a typed Request
public protocol BackendServiceProtocol: AnyObject {

    /// Determines how the backend service should recover from errors, should the `Request` be able to do so. If multiple `RecoveryStrategy` objects are present,
    /// they are executed in order until one attempts to recover from the failure. If no `RecoveryStrategy` is present, all errors are returned directly to the client.
    var recoveryStrategies: [RecoveryStrategy] { get }

    /// Executes the Request, calling the provided completion block when finished.
    ///
    /// - Parameters:
    ///   - request: The Request to be executed.
    ///   - completion: The completion block to invoke when execution has finished.
    func execute<R, E>(request: Request<R, E>, completion: @escaping (Result<R, E>) -> Void)

    /// Cancels the task for the given request (if it is currently running).
    func cancelTask(for request: URLRequest)
    
    /// Cancels all currently running tasks
    func cancelAllTasks()
}

// MARK: - BackendServiceProtocol Default Implementations

public extension BackendServiceProtocol {
    
    var recoveryStrategies: [RecoveryStrategy] { return [] }
    
    /// Attempt to recover from an error encountered when executing a request.
    /// - Parameters:
    ///   - error: The error encountered when executing the request.
    ///   - request: The request that was executing.
    ///   - completion: The completion which should be executed when the recovery attempt is complete. In the case the recovery succeeds,
    ///   this completion is passed to the recovered `Request` instance. In the case of a failed recovery, the completion should be passed an error.
    func attemptToRecover<R, E>(from error: E, executing request: Request<R, E>, completion: @escaping (Result<R, E>) -> Void) {
        guard let recoveryStrategy = recoveryStrategies.first(where: { $0.canAttemptRecovery(from: error, for: request) }) else {
            return executeOnMainThread(completion(.failure(error)))
        }
        
        recoveryStrategy.attemptRecovery(for: request, with: error) { [weak self] disposition in
            switch disposition {
            case .retry(let recovered): self?.execute(request: recovered, completion: completion)
            case .fail: self?.executeOnMainThread(completion(.failure(error)))
            }
        }
    }
    
    /// Guarantees execution of a closure on the main thread.
    /// - Parameter closure: The work that needs to be performed.
    func executeOnMainThread(_ closure: @autoclosure @escaping () -> Void) {
        guard !Thread.isMainThread else { return closure() }
        DispatchQueue.main.async {
            closure()
        }
    }
}

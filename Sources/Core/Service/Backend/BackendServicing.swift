//
//  BackendServiceProtocol.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents something that's capable of executing a typed Request
public protocol BackendServicing: AnyObject {

    /// Determines how the backend service should recover from errors, should the `Request` be able to do so. If multiple `RecoveryStrategy` objects are present,
    /// they are executed in order until one attempts to recover from the failure. If no `RecoveryStrategy` is present, all errors are returned directly to the client.
    var recoveryStrategies: [RecoveryStrategy] { get }

    /// Executes the Request, calling the provided completion block when finished.
    ///
    /// - Parameters:
    ///   - request: The Request to be executed.
    ///   - completion: The completion block to invoke when execution has finished.
    func execute<R>(request: Request<R>, delegate: TransportTaskDelegate?) async throws -> R
}

// MARK: - BackendServiceProtocol Default Implementations

public extension BackendServicing {
    
    var recoveryStrategies: [RecoveryStrategy] { return [] }
    
    /// Attempt to recover from an error encountered when executing a request.
    /// - Parameters:
    ///   - error: The error encountered when executing the request.
    ///   - request: The request that was executing.
    ///   - completion: The completion which should be executed when the recovery attempt is complete. In the case the recovery succeeds,
    ///   this completion is passed to the recovered `Request` instance. In the case of a failed recovery, the completion should be passed an error.
    func attemptToRecover<R>(from error: Error, executing request: Request<R>, delegate: TransportTaskDelegate? = nil) async throws -> R {
        for strategy in recoveryStrategies {
            let recoveryDisposition = await strategy.attemptRecovery(from: error, executing: request)

            switch recoveryDisposition {
            case .noAttemptMade: continue
            case .fail: throw error
            case .retry(let recoveredRequest): return try await execute(request: recoveredRequest, delegate: delegate)
            }
        }

        throw error
    }
}

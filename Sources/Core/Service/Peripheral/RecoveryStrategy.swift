//
//  RecoverableBackendService.swift
//  Hyperspace
//
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation

// MARK: - Recoverable

/// Represents an operation that can be attempted multiple times in the event of failure.
public protocol Recoverable {
    
    /// The number of recovery attempts that this operation has made
    var recoveryAttemptCount: UInt { get set }
    
    /// The maximum number of attempts that this operation should make before completely aborting. This value is nil when there is no maximum.
    var maxRecoveryAttempts: UInt? { get }
}

// MARK: - Recoverable Default Implementations
public extension Recoverable {
    
    /// The ability of this operation to recover from the last encountered failure.
    var isRecoverable: Bool {
        return maxRecoveryAttempts.map { recoveryAttemptCount < $0 } ?? true
    }
    
    /// Creates a new copy of the operation ready for a new attempt to be made.
    ///
    /// - Returns: A new `Self`, with updated recoverability information.
    func updatedForNextAttempt() -> Self? {
        guard isRecoverable else { return nil }
        var copy = self
        copy.recoveryAttemptCount += 1
        return copy
    }
}

// MARK: - RecoveryDisposition

/// The action to take in response to a recovery attempt.
///
/// - retry: The action should be retried with the supplied instance of `Request`.
/// - fail: The action should be aborted, the failure returned to the caller.
public enum RecoveryDisposition<Request> {
    case noAttemptMade
    case fail
    case retry(Request)
}

// MARK: - RecoveryStrategy

/// Represents a type that is capable of determining the recovery strategy for a failed `Request`.
public protocol RecoveryStrategy {

    /// Handle the recovery attempt. The object should asynchronously determine and return the correct `RecoveryDisposition` in order to determine the next action taken.
    /// - Parameters:
    ///   - request: The object that encountered a failure.
    ///   - error: The specific failure returned by the operation.
    ///   - completion: The handler to execute once the `RecoveryDisposition` has been determined.
    func attemptRecovery<R>(from error: Error, executing request: Request<R>) async -> RecoveryDisposition<Request<R>>
}

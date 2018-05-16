//
//  RecoverableBackendService.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 5/16/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// The action to take in response to a recovery attempt.
///
/// - retry: The action should be retried with the supplied instance of `T`.
/// - fail: The action should be aborted, the failure returned to the caller.
public enum RecoveryDisposition<T> {
    case retry(T)
    case fail
}

/// Represents a type that is capable of determining the recovery strategy for a failed `Recoverable & NetworkRequest`.
public protocol RecoveryStrategy {
    
    /// Handle the recovery attempt. The object should asynchronously determine and return the correct RecoveryDisposition in order to determine the next action taken.
    ///
    /// - Parameters:
    ///   - request: The object that encountered a failure.
    ///   - error: The specific failure returned by the operation.
    ///   - completion: The handler to execute once the RecoveryDisposition has been determined.
    func handleRecoveryAttempt<T: Recoverable & NetworkRequest>(for request: T, withError error: T.ErrorType, completion: @escaping (RecoveryDisposition<T>) -> Void)
}

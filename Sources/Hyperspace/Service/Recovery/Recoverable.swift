//
//  Recoverable.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 5/16/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents an operation that can be attempted multiple times in the event of failure.
public protocol Recoverable {
    
    /// The number of attempts that this operation has made
    var recoveryAttemptCount: UInt { get set }
    
    /// The maximum number of attempts that this operation should make before completely aborting.
    var maxRecoveryAttempts: UInt? { get }
}

extension Recoverable {
    
    /// The ability of this operation to recover from the last encountered failure.
    var isRecoverable: Bool {
        return recoveryAttemptCount < maxRecoveryAttempts ?? .max
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

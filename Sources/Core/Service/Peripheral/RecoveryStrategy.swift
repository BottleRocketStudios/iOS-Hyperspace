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
    case notAttempted
    case failure(Error)
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

// MARK: - DateFormatter + Retry

extension DateFormatter {

    /// Originally defined in: https://datatracker.ietf.org/doc/html/rfc822#section-5
    /// Updated in: https://datatracker.ietf.org/doc/html/rfc1123#section-5.2.14
    static let httpDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return formatter
    }()
}

// MARK: - BackoffStrategy

public protocol BackoffStrategy {

    func delay(forRetryCount count: UInt, afterReceiving error: Error) -> TimeInterval
}

public extension BackoffStrategy {

    func retryInterval(from headers: [HTTP.HeaderKey: HTTP.HeaderValue]?, currentDate: Date = .now) -> TimeInterval? {
        if let interval = headers?[.retryAfter].map({ TimeInterval($0.rawValue) }) {
            return interval
        } else if let futureDate = headers?[.retryAfter].flatMap({ DateFormatter.httpDate.date(from: $0.rawValue) }) {
            return futureDate.timeIntervalSince(currentDate)
        }

        return nil
    }
}

public struct ExponentialBackoff: BackoffStrategy {

    // MARK: - Properties
    public var maximumDelay: TimeInterval?
    public var jitter: ClosedRange<TimeInterval>?

    // MARK: - BackoffStrategy
    public func delay(forRetryCount count: UInt, afterReceiving error: Error) -> TimeInterval {
        var delay = TimeInterval(pow(2.0, Float(count))) * 1000

        if let jitter {
            delay += TimeInterval.random(in: jitter)
        }

        return maximumDelay.map { min($0, delay) } ?? delay
    }
}

public struct HeaderBackoff: BackoffStrategy {

    // MARK: - Properties
    public var defaultDelay: TimeInterval

    // MARK: - BackoffStrategy
    public func delay(forRetryCount count: UInt, afterReceiving error: Error) -> TimeInterval {
        guard let transportFailure = error as? TransportFailure, let response = transportFailure.response else { return defaultDelay }
        return retryInterval(from: response.headers) ?? defaultDelay
    }
}

// MARK: - BackoffRecoveryStrategy

public struct BackoffRecoveryStrategy: RecoveryStrategy {

    // MARK: - Properties
    public var handleDecision: (Error) -> Bool
    public var backoffStrategy: BackoffStrategy

    // MARK: - Initializers
    public init(backoffStrategy: BackoffStrategy, handlingStatuses: [HTTP.Status] = [.serverError(.serviceUnavailable)]) {
        self.init(backoffStrategy: backoffStrategy) {
            guard let failure = $0 as? TransportFailure, let response = failure.response else { return false }

            return handlingStatuses.contains(response.status)
        }
    }

    public init(backoffStrategy: BackoffStrategy, handleDecision: @escaping (Error) -> Bool) {
        self.handleDecision = handleDecision
        self.backoffStrategy = backoffStrategy
    }

    // MARK: - RecoveryStrategy
    public func attemptRecovery<R>(from error: Error, executing request: Request<R>) async -> RecoveryDisposition<Request<R>> {
        guard handleDecision(error) else { return .notAttempted }
        guard let nextAttempt = request.updatedForNextAttempt() else { return .failure(error) }

        do {
            let backoff = backoffStrategy.delay(forRetryCount: nextAttempt.recoveryAttemptCount, afterReceiving: error)
            try await Task.sleep(seconds: backoff)
            return .retry(nextAttempt)

        } catch {
            return .failure(error)
        }
    }
}

//
//  BackendServiceProtocol.swift
//  Hyperspace
//
//  Created by Tyler Milner on 7/10/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public enum DecodingFailure: Error {

    // MARK: - Context Subtype

    public struct Context {
        let decodingError: DecodingError
        let failingType: Decodable.Type
        let response: HTTP.Response
    }

    case invalidEmptyResponse(HTTP.Response)
    case decodingError(Context)

    // MARK: - Interface

    public var response: HTTP.Response {
        switch self {
        case .invalidEmptyResponse(let response): return response
        case .decodingError(let context): return context.response
        }
    }

    public var decodingContext: Context? {
        switch self {
        case .decodingError(let context): return context
        default: return nil
        }
    }

    // MARK: - Convenience

    static func genericFailure(decoding: Decodable.Type, from response: HTTP.Response, debugDescription: String) -> DecodingFailure {
        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: debugDescription))
        let context = DecodingFailure.Context(decodingError: decodingError, failingType: decoding, response: response)
        return .decodingError(context)
    }
}

/// Represents an error which can be constructed from a `DecodingError` and `Data`.
public protocol DecodingFailureRepresentable: TransportFailureRepresentable {

    init(decodingFailure: DecodingFailure)
}

public extension DecodingFailureRepresentable {

    init(context: DecodingFailure.Context) {
        self.init(decodingFailure: .decodingError(context))
    }
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

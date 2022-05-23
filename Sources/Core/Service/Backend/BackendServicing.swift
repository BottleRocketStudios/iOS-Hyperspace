//
//  BackendServiceProtocol.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public enum DecodingFailure: Error {

    // MARK: - Context Subtype
    public struct Context {
        public let decodingError: DecodingError
        public let failingType: Decodable.Type
        public let response: HTTP.Response
        
        public init(decodingError: DecodingError, failingType: Decodable.Type, response: HTTP.Response) {
            self.decodingError = decodingError
            self.failingType = failingType
            self.response = response
        }
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
        case .invalidEmptyResponse: return nil
        case .decodingError(let context): return context
        }
    }

    // MARK: - Convenience

    public static func genericFailure(decoding: Decodable.Type, from response: HTTP.Response, debugDescription: String) -> DecodingFailure {
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
public protocol BackendServicing: AnyObject {

    /// Determines how the backend service should recover from errors, should the `Request` be able to do so. If multiple `RecoveryStrategy` objects are present,
    /// they are executed in order until one attempts to recover from the failure. If no `RecoveryStrategy` is present, all errors are returned directly to the client.
    var recoveryStrategies: [RecoveryStrategy] { get }

    /// Executes the Request, calling the provided completion block when finished.
    ///
    /// - Parameters:
    ///   - request: The Request to be executed.
    ///   - completion: The completion block to invoke when execution has finished.
    func execute<R>(request: Request<R>) async throws -> R

    /// Cancels the task for the given request (if it is currently running).
//    func cancelTask(for request: URLRequest)
//    
//    /// Cancels all currently running tasks
//    func cancelAllTasks()
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
    func attemptToRecover<R>(from error: Error, executing request: Request<R>) async throws -> R {
        for strategy in recoveryStrategies {
            let recoveryDisposition = await strategy.attemptRecovery(from: error, executing: request)

            switch recoveryDisposition {
            case .noAttemptMade: continue
            case .fail: throw error
            case .retry(let recoveredRequest): return try await execute(request: recoveredRequest)
            }
        }

        throw error
    }
}

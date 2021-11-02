//
//  BackendService+Async.swift
//  Hyperspace-iOS
//
//  Created by Daniel Larsen on 10/30/21.
//  Copyright © 2021 Bottle Rocket Studios. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension BackendServiceProtocol {

    /// Executes the Request asynchronously, returning the specified value type. Throws an error if unable to return the value as specified.
    ///
    /// - Parameters:
    ///   - request: The Request to be executed.
    /// - Returns: The decodable type specified in the `Request`.
    public func execute<T, U>(request: Request<T, U>) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            execute(request: request) { result in
                switch result {
                case .success(let value): continuation.resume(returning: value)
                case .failure(let err): continuation.resume(throwing: err)
                }
            }
        }
    }

    /// Executes the Request asynchronously without throwing any errors
    ///
    /// - Parameters:
    ///   - request: The Request to be executed.
    /// - Returns: A `Result` of given value type `T` and error type `U`.
    public func executeWithResult<T, U>(request: Request<T, U>) async -> Result<T, U> {
        return await withCheckedContinuation { continuation in
            execute(request: request) { result in
                switch result {
                case .success(let value): continuation.resume(with: .success(Result<T, U>.success(value)))
                case .failure(let err): continuation.resume(with: .success(Result<T, U>.failure(err)))
                }
            }
        }
    }
}

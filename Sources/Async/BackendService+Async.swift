//
//  BackendService+Async.swift
//  Hyperspace-iOS
//
//  Created by Daniel Larsen on 10/30/21.
//  Copyright © 2021 Bottle Rocket Studios. All rights reserved.
//

import Foundation

extension BackendServiceProtocol {

    /// Executes the Request, returning the specified value type. Throws an error if unable to return the value as specified.
    ///
    /// - Parameters:
    ///   - request: The Request to be executed.
    /// - Returns: The decodable type specified in the `Request`.
    @available(iOSApplicationExtension 13.0.0, *)
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
}

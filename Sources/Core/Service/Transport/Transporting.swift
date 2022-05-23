//
//  Transporting.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents something that can execute a URLRequest.
public protocol Transporting {
    
    /// Executes the `URLRequest`, calling the provided completion block when complete.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` to execute.
    ///   - completion: The completion block to be invoked when request execution is complete.
    func execute(request: URLRequest, delegate: TransportTaskDelegate?) async throws -> TransportResult
}

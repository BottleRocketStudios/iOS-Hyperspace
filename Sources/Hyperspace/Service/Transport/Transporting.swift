//
//  Transporting.swift
//  Hyperspace
//
//  Created by Tyler Milner on 7/10/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents the possible resulting values of a `Request` using a `TransportService`.
public typealias TransportResult = Result<TransportSuccess, TransportFailure>

/// Represents something that can execute a URLRequest.
public protocol Transporting {
    
    /// Executes the `URLRequest`, calling the provided completion block when complete.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` to execute.
    ///   - completion: The completion block to be invoked when request execution is complete.
    func execute(request: URLRequest, completion: @escaping (TransportResult) -> Void)
    
    /// Cancels the task for the given request (if it is currently running).
    func cancelTask(for request: URLRequest)

    /// Cancels all currently running tasks
    func cancelAllTasks()
}

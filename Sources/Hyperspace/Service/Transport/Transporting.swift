//
//  Transporting.swift
//  Hyperspace
//
//  Created by Tyler Milner on 7/10/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

@available(*, renamed: "TransportResult")
public typealias NetworkServiceResult = TransportResult

/// Represents the possible resulting values of a `Request` using a `TransportService`.
public typealias TransportResult = Result<TransportSuccess, TransportFailure>

public extension TransportResult {

    var request: HTTP.Request {
        switch self {
        case .success(let success): return success.request
        case .failure(let failure): return failure.request
        }
    }

    var response: HTTP.Response? {
        switch self {
        case .success(let success): return success.response
        case .failure(let failure): return failure.response
        }
    }
}

@available(*, renamed: "Transporting")
public typealias NetworkServiceProtocol = Transporting

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

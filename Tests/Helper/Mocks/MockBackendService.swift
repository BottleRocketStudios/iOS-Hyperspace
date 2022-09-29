//
//  MockBackendService.swift
//  Tests
//
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation
@testable import Hyperspace

class MockBackendService: BackendServicing {

    func execute<R>(request: Request<R>) async throws -> R {
        return try await execute(request: request, delegate: nil)
    }

    func execute<R>(request: Request<R>, delegate: TransportTaskDelegate?) async throws -> R {
        throw TransportFailure(kind: .clientError(.requestTimeout), request: HTTP.Request(urlRequest: request.urlRequest), response: nil)
    }

    func cancelTask(for request: URLRequest) {
        /* No op */
    }

    func cancelAllTasks() {
        /* No op */
    }
}

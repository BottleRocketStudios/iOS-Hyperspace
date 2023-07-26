//
//  MockTransportService.swift
//  Tests
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace

class MockTransportService {

    private(set) var executeCallCount = 0
    private(set) var lastExecutedURLRequest: URLRequest?
    var responseResult: Result<TransportSuccess, TransportFailure>

    init(responseResult: Result<TransportSuccess, TransportFailure>) {
        self.responseResult = responseResult
    }
}

// MARK: - Transporting
extension MockTransportService: Transporting {

    func execute(request: URLRequest) async throws -> TransportSuccess {
        return try await execute(request: request, delegate: nil)
    }

    func execute(request: URLRequest, delegate: TransportTaskDelegate?) async throws -> TransportSuccess {
        lastExecutedURLRequest = request
        executeCallCount += 1

        switch responseResult {
        case .success(let success):
            return .init(response: .init(request: .init(urlRequest: request), code: success.response.code, url: success.response.url, headers: success.response.headers, body: success.response.body))
        case .failure(let failure):
            throw TransportFailure(kind: failure.kind, request: .init(urlRequest: request), response: failure.response)
        }
    }
}

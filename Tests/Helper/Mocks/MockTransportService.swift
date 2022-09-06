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

extension MockTransportService: Transporting {

    func execute(request: URLRequest, delegate: TransportTaskDelegate?) async throws -> TransportSuccess {
        lastExecutedURLRequest = request
        executeCallCount += 1

        switch responseResult {
        case .success(let success): return success
        case .failure(let failure): throw failure
        }
    }
}

//
//  FutureTests.swift
//  Hyperspace-iOS
//
//  Created by Pranjal Satija on 1/8/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import XCTest
import BrightFutures
@testable import Hyperspace

class FutureTests: XCTestCase {
    
    // MARK: - Type Aliases
    typealias DefaultModel = RequestTestDefaults.DefaultModel
    
    // MARK: - Properties
    private let defaultModelJSONData = RequestTestDefaults.defaultModelJSONData
    private let defaultRequest: Request<DefaultModel, MockBackendServiceError> = RequestTestDefaults.defaultRequest()
    
    // MARK: - Tests
    func test_FailingRequestAlsoFailsFuture() {
        let failure = TransportFailure(error: TransportError(code: .noInternetConnection), response: nil)
        executeBackendRequest(expectedResult: .failure(failure))
    }
    
    func test_SuccessfulResultAlsoSucceedsFuture() {
        let success = TransportSuccess(response: HTTP.Response(code: 200, data: defaultModelJSONData))
        executeBackendRequest(expectedResult: .success(success))
    }
    
    // MARK: - Private Helpers
    private func executeBackendRequest(expectedResult: TransportResult, file: StaticString = #file, line: UInt = #line) {
        let expectation = self.expectation(description: "\(BackendService.self) Completion")
        
        let transportService = MockTransportService(responseResult: expectedResult)
        let backendService = BackendService(transportService: transportService)
        
        backendService.execute(request: defaultRequest).onSuccess { _ in
            XCTAssertTrue(expectedResult.isSuccess, file: file, line: line)
            expectation.fulfill()
        }.onFailure { _ in
            XCTAssertTrue(expectedResult.isFailure, file: file, line: line)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
}

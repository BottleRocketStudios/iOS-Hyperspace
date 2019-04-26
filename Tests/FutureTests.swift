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
    // MARK: Type Aliases
    typealias DefaultModel = RequestTestDefaults.DefaultModel
    
    // MARK: Properties
    private let defaultModelJSONData = RequestTestDefaults.defaultModelJSONData
    private let defaultRequest = RequestTestDefaults.DefaultRequest<DefaultModel>()
    private let defaultSuccessResponse = HTTP.Response(code: 200, data: nil)
    
    // MARK: Tests
    func test_FailingRequestAlsoFailsFuture() {
        let failure = NetworkServiceFailure(error: .noData, response: nil)
        executeBackendRequest(expectedResult: .failure(failure))
    }
    
    func test_SuccessfulResultAlsoSucceedsFuture() {
        let success = NetworkServiceSuccess(data: defaultModelJSONData, response: defaultSuccessResponse)
        executeBackendRequest(expectedResult: .success(success))
    }
    
    // MARK: Private Helpers
    private func executeBackendRequest(expectedResult: Result<NetworkServiceSuccess, NetworkServiceFailure>, file: StaticString = #file, line: UInt = #line) {
        let expectation = self.expectation(description: "\(BackendService.self) Completion")
        
        let networkService = MockNetworkService(responseResult: expectedResult)
        let backendService = BackendService(networkService: networkService, recoveryStrategy: nil)
        
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

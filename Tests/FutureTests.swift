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
import Result

class FutureTests: XCTestCase {
    typealias DefaultModel = RequestTestDefaults.DefaultModel
    
    private let defaultModelJSONData = RequestTestDefaults.defaultModelJSONData
    private let defaultRequest = RequestTestDefaults.DefaultRequest<DefaultModel>()
    private let defaultSuccessResponse = HTTP.Response(code: 200, data: nil)
    
    func test_FailingRequestAlsoFailsFuture() {
        let failure = NetworkServiceFailure(error: .noData, response: nil)
        executeBackendRequest(expectedResult: .failure(failure))
    }
    
    func test_SuccessfulResultAlsoSucceedsFuture() {
        let success = NetworkServiceSuccess(data: defaultModelJSONData, response: defaultSuccessResponse)
        executeBackendRequest(expectedResult: .success(success))
    }
    
    private func executeBackendRequest(expectedResult: Result<NetworkServiceSuccess, NetworkServiceFailure>) {
        let expectation = self.expectation(description: "\(BackendService.self) Completion")
        
        let networkService = MockNetworkService(responseResult: expectedResult)
        let backendService = BackendService(networkService: networkService, recoveryStrategy: nil)
        
        backendService.execute(request: defaultRequest).onSuccess { _ in
            if !expectedResult.isSuccess {
                XCTFail("The expected result was not success, but the Future succeeded.")
            }
            
            expectation.fulfill()
        }.onFailure { _ in
            if !expectedResult.isFailure {
                XCTFail("The expected result was not failure, but the Future failed.")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }
}

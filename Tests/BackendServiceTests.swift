//
//  BackendServiceTests.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/29/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class BackendServiceTests: XCTestCase {
    
    // MARK: - Typealias
    
    typealias DefaultModel = RequestTestDefaults.DefaultModel
    
    // MARK: - Properties
    
    private let modelJSONData = RequestTestDefaults.defaultModelJSONData
    private let defaultRequest: Request<DefaultModel, MockBackendServiceError> = RequestTestDefaults.defaultRequest()
    private lazy var defaultHTTPRequest = HTTP.Request(urlRequest: defaultRequest.urlRequest)
    private lazy var defaultSuccessResponse = HTTP.Response(request: defaultHTTPRequest, code: 200, body: modelJSONData)

    // MARK: - Tests
    
    func test_TransportSuccess_TransformsResponseCorrectly() {
        let model = RequestTestDefaults.defaultModel
        let mockedResult = TransportSuccess(response: defaultSuccessResponse)
        
        executeBackendService(mockedTransportResult: .success(mockedResult), expectingResult: .success(model))
    }
    
    func test_TransportResponseTransformFailure_GeneratesDataTransformationError() {
        let invalidJSONData = "test".data(using: .utf8)!
        let response = HTTP.Response(request: defaultHTTPRequest, code: 200, body: invalidJSONData)
        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "The given data was not valid JSON."))
        let jsonDecodingError = DecodingFailure.decodingError(.init(decodingError: decodingError, failingType: DefaultModel.self, response: response))
        let mockedResult = TransportSuccess(response: response)
        
        executeBackendService(mockedTransportResult: .success(mockedResult), expectingResult: .failure(.dataTransformationError(jsonDecodingError)))
    }
    
    func test_TransportNetworkFailure_GeneratesNetworkError() {
        let response = HTTP.Response(request: HTTP.Request(), code: 503, body: nil)
        let mockedResult = TransportFailure(error: .init(code: .serverError(.serviceUnavailable)), response: response)
        
        executeBackendService(mockedTransportResult: .failure(mockedResult), expectingResult: .failure(.networkError(.init(code: .serverError(.serviceUnavailable)), response)))
    }
    
    func test_ExecutingBackendService_ExecutesUnderlyingTransport() {
        let mockedResult = TransportSuccess(response: defaultSuccessResponse)
        let mockTransportService = MockTransportService(responseResult: .success(mockedResult))
        
        let backendService = BackendService(transportService: mockTransportService)
        backendService.execute(request: defaultRequest) { (_) in }
        
        XCTAssertEqual(mockTransportService.executeCallCount, 1)
    }
    
    func test_CancellingBackendService_CancelsUnderlyingTransportService() {
        let mockedResult = TransportSuccess(response: defaultSuccessResponse)
        let mockTransportService = MockTransportService(responseResult: .success(mockedResult))
        
        let backendService = BackendService(transportService: mockTransportService)
        let request = URLRequest(url: RequestTestDefaults.defaultURL)
        backendService.cancelTask(for: request)
        
        XCTAssertEqual(mockTransportService.cancelCallCount, 1)
        XCTAssertEqual(mockTransportService.lastCancelledURLRequest, request)
    }
    
    func test_BackendServiceDeinit_CancelsAllTasksForUnderlyingTransportService() {
        let mockedResult = TransportSuccess(response: defaultSuccessResponse)
        let mockTransportService = MockTransportService(responseResult: .success(mockedResult))
        
        var backendService: BackendService? = BackendService(transportService: mockTransportService)
        backendService = nil
        XCTAssertNil(backendService) // To silence the "variable was written to, but never read" warning. See https://stackoverflow.com/a/32861678/4343618
        
        XCTAssertEqual(mockTransportService.cancelAllTasksCallCount, 1)
    }

    func test_BackendService_DefaultsToEmptyArrayOfRecoveryStrategies() {
        let service = MockBackendService()
        XCTAssertTrue(service.recoveryStrategies.isEmpty)
    }
    
    // MARK: - Private
    
    private func executeBackendService(mockedTransportResult: TransportResult,
                                       expectingResult expectedResult: Result<DefaultModel, MockBackendServiceError>,
                                       file: StaticString = #file,
                                       line: UInt = #line) {
        let mockTransportService = MockTransportService(responseResult: mockedTransportResult)
        let backendService = BackendService(transportService: mockTransportService)
        
        let asyncExpectation = expectation(description: "\(BackendService.self) completion")
        
        let request = defaultRequest
        backendService.execute(request: request) { result in            
            switch (result, expectedResult) {
            case (.success(let resultObject), .success(let expectedObject)):
                XCTAssertEqual(resultObject, expectedObject, file: file, line: line)
            case (.failure(let resultError), .failure(let expectedError)):
                XCTAssertEqual(resultError, expectedError, file: file, line: line)
            default:
                XCTFail("Result '\(result)' not equal to expected result '\(expectedResult)'", file: file, line: line)
            }
            
            asyncExpectation.fulfill()
        }
        
        XCTAssertEqual(mockTransportService.lastExecutedURLRequest, request.urlRequest, file: file, line: line)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

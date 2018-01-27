//
//  NetworkServiceTests.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/29/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace
import Result

class NetworkServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private let defaultRequest = URLRequest(url: NetworkRequestTestDefaults.defaultURL)
    
    // MARK: - Tests
    
    func test_MissingURLResponse_GeneratesUnknownError() {
        let expectedResult = NetworkServiceFailure(error: .unknownError, response: nil)
        executeNetworkServiceUsingMockHTTPResponse(nil, expectingResult: .failure(expectedResult))
    }
    
    func test_InvalidStatusCode_GeneratesUnknownStatusCodeError() {
        let response = HTTP.Response(code: 0, data: nil)
        let expectedResult = NetworkServiceFailure(error: .unknownStatusCode, response: response)
        
        executeNetworkServiceUsingMockHTTPResponse(response, expectingResult: .failure(expectedResult))
    }
    
    func test_SuccessResponseWithNoData_GeneratesNoDataError() {
        let response = HTTP.Response(code: 200, data: nil)
        let expectedResult = NetworkServiceFailure(error: .noData, response: response)
        
        executeNetworkServiceUsingMockHTTPResponse(response, expectingResult: .failure(expectedResult))
    }
    
    func test_SuccessResponseWithData_Succeeds() {
        let responseData = "test".data(using: .utf8)!
        let response = HTTP.Response(code: 200, data: responseData)
        let expectedResult = NetworkServiceSuccess(data: responseData, response: response)
        
        executeNetworkServiceUsingMockHTTPResponse(response, expectingResult: .success(expectedResult))
    }
    
    func test_300Status_GeneratesRedirectionError() {
        let response = HTTP.Response(code: 300, data: nil)
        let expectedResult = NetworkServiceFailure(error: .redirection, response: response)
        
        executeNetworkServiceUsingMockHTTPResponse(response, expectingResult: .failure(expectedResult))
    }
    
    func test_400Status_GeneratesClientError() {
        let response = HTTP.Response(code: 400, data: nil)
        let expectedResult = NetworkServiceFailure(error: .clientError(.badRequest), response: response)
        
        executeNetworkServiceUsingMockHTTPResponse(response, expectingResult: .failure(expectedResult))
    }
    
    func test_500Status_GeneratesServerError() {
        let response = HTTP.Response(code: 500, data: nil)
        let expectedResult = NetworkServiceFailure(error: .serverError(.internalServerError), response: response)
        
        executeNetworkServiceUsingMockHTTPResponse(response, expectingResult: .failure(expectedResult))
    }
    
    func test_NoInternet_GeneratesNoInternetError() {
        let connectionError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let expectedResult = NetworkServiceFailure(error: .noInternetConnection, response: nil)
        
        executeNetworkServiceUsingMockHTTPResponse(nil, mockError: connectionError, expectingResult: .failure(expectedResult))
    }
    
    func test_RequestTimeout_GeneratesTimeoutError() {
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        let expectedResult = NetworkServiceFailure(error: .timedOut, response: nil)
        
        executeNetworkServiceUsingMockHTTPResponse(nil, mockError: timeoutError, expectingResult: .failure(expectedResult))
    }
    
    func test_CancellingRequest_GeneratesCancellationError() {
        let cancellationError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
        let expectedResult = NetworkServiceFailure(error: .cancelled, response: nil)
        
        executeNetworkServiceUsingMockHTTPResponse(nil, mockError: cancellationError, expectingResult: .failure(expectedResult))
    }
    
    func test_ExecutingNetworkService_ExecutesDataTask() {
        let dataTask = MockNetworkSessionDataTask(request: defaultRequest)
        
        _ = execute(dataTask: dataTask)
        
        XCTAssertEqual(dataTask.resumeCallCount, 1)
    }
    
    func test_CancellingNetworkService_CancelsDataTask() {
        let dataTask = MockNetworkSessionDataTask(request: defaultRequest)
        
        let service = execute(dataTask: dataTask)
        
        service.cancelTask(for: defaultRequest)
        
        XCTAssertEqual(dataTask.cancelCallCount, 1)
    }
    
    func test_NetworkServiceDeinit_CancelsDataTask() {
        let dataTask = MockNetworkSessionDataTask(request: URLRequest(url: NetworkRequestTestDefaults.defaultURL))
        
        var service: NetworkServiceProtocol? = execute(dataTask: dataTask)
        service = nil
        XCTAssertNil(service) // To silence the "variable was written to, but never read" warning. See https://stackoverflow.com/a/32861678/4343618
        
        XCTAssertEqual(dataTask.cancelCallCount, 1)
    }
    
    // MARK: - Private
    
    private func execute(dataTask: NetworkSessionDataTask) -> NetworkServiceProtocol {
        let mockSession = MockNetworkSession(responseStatusCode: nil, responseData: nil, error: nil)
        mockSession.nextDataTask = dataTask
        
        let service = NetworkService(session: mockSession)
        
        service.execute(request: defaultRequest) { (_) in }
        
        return service
    }
    
    private func executeNetworkServiceUsingMockHTTPResponse(_ mockHTTPResponse: HTTP.Response?,
                                                            mockError: Error? = nil,
                                                            expectingResult expectedResult: Result<NetworkServiceSuccess, NetworkServiceFailure>,
                                                            file: StaticString = #file,
                                                            line: UInt = #line) {
        let mockSession = MockNetworkSession(responseStatusCode: mockHTTPResponse?.code, responseData: mockHTTPResponse?.data, error: mockError)
        executeNetworkService(using: mockSession, expectingResult: expectedResult, file: file, line: line)
    }
    
    private func executeNetworkService(using session: NetworkSession, expectingResult expectedResult: Result<NetworkServiceSuccess, NetworkServiceFailure>, file: StaticString = #file, line: UInt = #line) {
        let service = NetworkService(session: session)
        
        let asyncExpectation = expectation(description: "\(NetworkService.self) completion")
        
        service.execute(request: defaultRequest) { (result) in
            XCTAssertTrue(result == expectedResult, file: file, line: line)
            asyncExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

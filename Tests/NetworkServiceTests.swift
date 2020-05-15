//
//  NetworkServiceTests.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/29/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class NetworkServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private let defaultRequest = URLRequest(url: RequestTestDefaults.defaultURL)
    
    // MARK: - Tests
    
    func test_MissingURLResponse_GeneratesUnknownError() {
        let expectedResult = TransportFailure(error: .init(code: .unknownError), response: nil)
        executeNetworkServiceUsingMockHTTPResponse(nil, expectingResult: .failure(expectedResult))
    }
        
//    func test_SuccessResponseWithNoData_GeneratesNoDataError() {
//        let response = HTTP.Response(code: 200, data: nil, headers: [:])
//        let expectedResult = TransportSuccess(response: response) (error: .noData, response: response)
//
//        executeNetworkServiceUsingMockHTTPResponse(response, expectingResult: .failure(expectedResult))
//    }
    
    func test_SuccessResponseWithData_Succeeds() {
        let responseData = "test".data(using: .utf8)!
        let response = HTTP.Response(code: 200, url: RequestTestDefaults.defaultURL, data: responseData, headers: [:])
        let expectedResult = TransportSuccess(response: response)
        
        executeNetworkServiceUsingMockHTTPResponse(response, expectingResult: .success(expectedResult))
    }
    
    func test_300Status_GeneratesRedirectionError() {
        let response = HTTP.Response(code: 300, url: RequestTestDefaults.defaultURL, data: nil, headers: [:])
        let expectedResult = TransportFailure(error: .init(code: .redirection), response: response)
        
        executeNetworkServiceUsingMockHTTPResponse(response, expectingResult: .failure(expectedResult))
    }
    
    func test_400Status_GeneratesClientError() {
        let response = HTTP.Response(code: 400, url: RequestTestDefaults.defaultURL, data: nil, headers: [:])
        let expectedResult = TransportFailure(error: .init(code: .clientError(.badRequest)), response: response)
        
        executeNetworkServiceUsingMockHTTPResponse(response, expectingResult: .failure(expectedResult))
    }
    
    func test_500Status_GeneratesServerError() {
        let response = HTTP.Response(code: 500, url: RequestTestDefaults.defaultURL, data: nil, headers: [:])
        let expectedResult = TransportFailure(error: .init(code: .serverError(.internalServerError)), response: response)
        
        executeNetworkServiceUsingMockHTTPResponse(response, expectingResult: .failure(expectedResult))
    }
    
    func test_NoInternet_GeneratesNoInternetError() {
        let connectionError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let expectedResult = TransportFailure(error: .init(code: .noInternetConnection), response: nil)
        
        executeNetworkServiceUsingMockHTTPResponse(nil, mockError: connectionError, expectingResult: .failure(expectedResult))
    }
    
    func test_RequestTimeout_GeneratesTimeoutError() {
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        let expectedResult = TransportFailure(error: .init(code: .timedOut), response: nil)
        
        executeNetworkServiceUsingMockHTTPResponse(nil, mockError: timeoutError, expectingResult: .failure(expectedResult))
    }
    
    func test_CancellingRequest_GeneratesCancellationError() {
        let cancellationError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
        let expectedResult = TransportFailure(error: .init(code: .cancelled), response: nil)
        
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
        let dataTask = MockNetworkSessionDataTask(request: URLRequest(url: RequestTestDefaults.defaultURL))
        let asyncExpectation = expectation(description: "\(TransportService.self) falls out of scope")
        
        var service: Transporting? = execute(dataTask: dataTask)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNil(service) // To silence the "variable was written to, but never read" warning. See https://stackoverflow.com/a/32861678/4343618
            XCTAssertEqual(dataTask.cancelCallCount, 1)
            asyncExpectation.fulfill()
        }
        service = nil
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_NetworkService_ConvenienceInit() {
        let networkService = NetworkServiceMockSubclass(session: URLSession.shared, networkActivityIndicatable: MockNetworkActivityIndicator())
        
        XCTAssert(networkService.initWithNetworkActivityControllerCalled)
    }
    
//    func test_NetworkServiceHelper_InvalidHTTPResponsErrorUnknownError() {
//        let networkServiceFailure = NetworkServiceHelper.networkServiceFailure(for: NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil))
//        XCTAssert(networkServiceFailure.error == .unknownError)
//    }
    
//    func test_NetworkServiceError_Equality() {
//        XCTAssertEqual(TransportError.unknownError, TransportError.unknownError)
//        XCTAssertEqual(TransportError.unknownStatusCode, TransportError.unknownStatusCode)
//        XCTAssertEqual(TransportError.redirection, TransportError.redirection)
//        XCTAssertEqual(TransportError.redirection, TransportError.redirection)
//        XCTAssertEqual(TransportError.clientError(.unauthorized), TransportError.clientError(.unauthorized))
//        XCTAssertEqual(TransportError.serverError(.badGateway), TransportError.serverError(.badGateway))
//        XCTAssertEqual(TransportError.noInternetConnection, TransportError.noInternetConnection)
//        XCTAssertEqual(TransportError.timedOut, TransportError.timedOut)
//        XCTAssertEqual(TransportError.cancelled, TransportError.cancelled)
//        XCTAssertNotEqual(TransportError.redirection, TransportError.cancelled)
//    }
    
    func test_AnyError_HasResponse() {
		let response = HTTP.Response(code: 1, data: nil)
        let error = AnyError(transportFailure: TransportFailure(error: .init(code: .cancelled), response: response))
        XCTAssertEqual(error.failureResponse, response)
    }
    
    // MARK: - Private
    
    private func execute(dataTask: NetworkSessionDataTask) -> Transporting {
        let mockSession = MockNetworkSession(responseStatusCode: nil, responseData: nil, error: nil)
        mockSession.nextDataTask = dataTask
        
        let service = TransportService(session: mockSession)
        service.execute(request: defaultRequest) { (_) in }
        
        return service
    }
    
    private func executeNetworkServiceUsingMockHTTPResponse(_ mockHTTPResponse: HTTP.Response?,
                                                            mockError: Error? = nil,
                                                            expectingResult expectedResult: TransportResult,
                                                            file: StaticString = #file,
                                                            line: UInt = #line) {
        let mockSession = MockNetworkSession(responseStatusCode: mockHTTPResponse?.code, responseData: mockHTTPResponse?.data, error: mockError)
        executeNetworkService(using: mockSession, expectingResult: expectedResult, file: file, line: line)
    }
    
    private func executeNetworkService(using session: NetworkSession, expectingResult expectedResult: TransportResult, file: StaticString = #file, line: UInt = #line) {
        let service = TransportService(session: session)
        let asyncExpectation = expectation(description: "\(TransportService.self) completion")
        
        service.execute(request: defaultRequest) { result in
            XCTAssertTrue(result == expectedResult, "Result '\(result)' did not equal expected result '\(expectedResult)'", file: file, line: line)
            asyncExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

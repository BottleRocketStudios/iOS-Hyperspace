//
//  TransportServiceTests.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/29/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class TransportServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private let defaultRequest = URLRequest(url: RequestTestDefaults.defaultURL)
    private lazy var defaultHTTPRequest = HTTP.Request(urlRequest: defaultRequest)
    
    // MARK: - Tests
    
    func test_TransportService_ProperlyInitializesWithSessionConfiguration() {
        let config = URLSessionConfiguration.ephemeral
        let service = TransportService(sessionConfiguration: config)
        
        XCTAssertEqual(service.session.configuration, config)
    }
    
    func test_MissingURLResponse_GeneratesUnknownError() {
        let expectedResult = TransportFailure(error: .init(code: .unknownError), request: defaultHTTPRequest, response: nil)
        executeTransportServiceUsingMockHTTPResponse(nil, expectingResult: .failure(expectedResult))
    }

    func test_MissingDataResponse_ReturnsNilData() {
        let response = HTTP.Response(request: defaultHTTPRequest, code: 200, url: RequestTestDefaults.defaultURL, headers: [:], body: nil)
        let expectedResult = TransportSuccess(response: response)

        executeTransportServiceUsingMockHTTPResponse(response, expectingResult: .success(expectedResult))
        XCTAssertNil(expectedResult.body)
    }
    
    func test_SuccessResponseWithData_Succeeds() {
        let responseData = "test".data(using: .utf8)!
        let response = HTTP.Response(request: defaultHTTPRequest, code: 200, url: RequestTestDefaults.defaultURL, headers: [:], body: responseData)
        let expectedResult = TransportSuccess(response: response)
        
        executeTransportServiceUsingMockHTTPResponse(response, expectingResult: .success(expectedResult))
    }
    
    func test_300Status_GeneratesRedirectionError() {
        let response = HTTP.Response(request: defaultHTTPRequest, code: 300, url: RequestTestDefaults.defaultURL, headers: [:], body: nil)
        let expectedResult = TransportFailure(code: .redirection, response: response)

        executeTransportServiceUsingMockHTTPResponse(response, expectingResult: .failure(expectedResult))
    }
    
    func test_400Status_GeneratesClientError() {
        let response = HTTP.Response(request: defaultHTTPRequest, code: 400, url: RequestTestDefaults.defaultURL, headers: [:], body: nil)
        let expectedResult = TransportFailure(code: .clientError(.badRequest), response: response)
        
        executeTransportServiceUsingMockHTTPResponse(response, expectingResult: .failure(expectedResult))
    }
    
    func test_500Status_GeneratesServerError() {
        let response = HTTP.Response(request: defaultHTTPRequest, code: 500, url: RequestTestDefaults.defaultURL, headers: [:], body: nil)
        let expectedResult = TransportFailure(code: .serverError(.internalServerError), response: response)
        
        executeTransportServiceUsingMockHTTPResponse(response, expectingResult: .failure(expectedResult))
    }
    
    func test_ClientErrorWithResponse_GeneratesDataLengthExceedsMaximumError() {
        let response = HTTP.Response(request: defaultHTTPRequest, code: 100, url: RequestTestDefaults.defaultURL, headers: [:], body: Data([1, 2, 3, 4, 5]))
        let exceedsMaxError = URLError(.dataLengthExceedsMaximum)
        let expectedResult = TransportFailure(error: TransportError(clientError: exceedsMaxError), response: response)
        
        executeTransportServiceUsingMockHTTPResponse(response, mockError: exceedsMaxError, expectingResult: .failure(expectedResult))
    }
    
    func test_NoInternet_GeneratesNoInternetError() {
        let connectionError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let expectedResult = TransportFailure(code: .noInternetConnection, request: defaultHTTPRequest, response: nil)
        
        executeTransportServiceUsingMockHTTPResponse(nil, mockError: connectionError, expectingResult: .failure(expectedResult))
    }
    
    func test_RequestTimeout_GeneratesTimeoutError() {
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        let expectedResult = TransportFailure(code: .timedOut, request: defaultHTTPRequest, response: nil)
        
        executeTransportServiceUsingMockHTTPResponse(nil, mockError: timeoutError, expectingResult: .failure(expectedResult))
    }
    
    func test_CancellingRequest_GeneratesCancellationError() {
        let cancellationError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
        let expectedResult = TransportFailure(code: .cancelled, request: defaultHTTPRequest, response: nil)
        
        executeTransportServiceUsingMockHTTPResponse(nil, mockError: cancellationError, expectingResult: .failure(expectedResult))
    }
    
    func test_ExecutingTransportService_ExecutesDataTask() {
        let dataTask = MockNetworkSessionDataTask(request: defaultRequest)
        
        _ = execute(dataTask: dataTask)
        
        XCTAssertEqual(dataTask.resumeCallCount, 1)
    }
    
    func test_CancellingTransportService_CancelsDataTask() {
        let dataTask = MockNetworkSessionDataTask(request: defaultRequest)
        let service = execute(dataTask: dataTask)
        
        service.cancelTask(for: defaultRequest)
        
        XCTAssertEqual(dataTask.cancelCallCount, 1)
    }
    
    func test_TransportServiceDeinit_CancelsDataTask() {
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
    
    func test_TransportService_ConvenienceInit() {
        let transportService = TransportServiceMockSubclass(session: URLSession.shared, networkActivityIndicatable: MockNetworkActivityIndicator())
        XCTAssert(transportService.initWithNetworkActivityControllerCalled)
    }
    
    func test_TransportServiceHelper_UncategorizedHTTPResponsErrorUnknownError() {
        let transportFailure = TransportFailure(error: .init(clientError: NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil)), request: HTTP.Request(), response: nil)
        guard case .other(URLError.badURL) = transportFailure.error.code else {
            return XCTFail("Given a .badURL URLError, the output should be of the same URLError")
        }
    }
    
    func test_TransportServiceHelper_InvalidHTTPResponsErrorUnknownError() {
        let transportFailure = TransportFailure(error: .init(clientError: NSError(domain: "somedomain", code: 1_000_000, userInfo: nil)), request: HTTP.Request(), response: nil)
        XCTAssert(transportFailure.error.code == .unknownError)
    }
    
    func test_TransportServiceError_Equality() {
        XCTAssertEqual(TransportError.Code.unknownError, TransportError.Code.unknownError)
        XCTAssertEqual(TransportError.Code.redirection, TransportError.Code.redirection)
        XCTAssertEqual(TransportError.Code.redirection, TransportError.Code.redirection)
        XCTAssertEqual(TransportError.Code.clientError(.unauthorized), TransportError.Code.clientError(.unauthorized))
        XCTAssertEqual(TransportError.Code.serverError(.badGateway), TransportError.Code.serverError(.badGateway))
        XCTAssertEqual(TransportError.Code.noInternetConnection, TransportError.Code.noInternetConnection)
        XCTAssertEqual(TransportError.Code.timedOut, TransportError.Code.timedOut)
        XCTAssertEqual(TransportError.Code.cancelled, TransportError.Code.cancelled)
        XCTAssertNotEqual(TransportError.Code.redirection, TransportError.Code.cancelled)
    }
    
    func test_AnyError_HasResponse() {
        let response = HTTP.Response(request: HTTP.Request(), code: 1, body: nil)
        let error = AnyError(transportFailure: TransportFailure(error: .init(code: .cancelled), response: response))
        XCTAssertEqual(error.failureResponse, response)
    }
    
    // MARK: - Private
    
    private func execute(dataTask: TransportDataTask) -> Transporting {
        let mockSession = MockNetworkSession(responseStatusCode: nil, responseData: nil, error: nil)
        mockSession.nextDataTask = dataTask
        
        let service = TransportService(session: mockSession)
        service.execute(request: defaultRequest) { (_) in }
        
        return service
    }
    
    private func executeTransportServiceUsingMockHTTPResponse(_ mockHTTPResponse: HTTP.Response?,
                                                              mockError: Error? = nil,
                                                              expectingResult expectedResult: TransportResult,
                                                              file: StaticString = #file,
                                                              line: UInt = #line) {
        let mockSession = MockNetworkSession(responseStatusCode: mockHTTPResponse?.code, responseData: mockHTTPResponse?.body, error: mockError)
        executeTransportService(using: mockSession, expectingResult: expectedResult, file: file, line: line)
    }
    
    private func executeTransportService(using session: TransportSession, expectingResult expectedResult: TransportResult, file: StaticString = #file, line: UInt = #line) {
        let service = TransportService(session: session)
        let asyncExpectation = expectation(description: "\(TransportService.self) completion")
        
        service.execute(request: defaultRequest) { result in
            XCTAssertTrue(result == expectedResult, "Result '\(result)' did not equal expected result '\(expectedResult)'", file: file, line: line)
            asyncExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

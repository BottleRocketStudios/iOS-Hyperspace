////
////  AsyncTests.swift
////  Tests
////
////  Copyright © 2021 Bottle Rocket Studios. All rights reserved.
////
//
//import Hyperspace
//import XCTest
//
//@available(iOS 13, tvOS 13, watchOS 6, *)
//class AsyncTests: XCTestCase {
//
//    // MARK: - Type Aliases
//    typealias DefaultModel = RequestTestDefaults.DefaultModel
//
//    // MARK: - Properties
//    private let defaultModelJSONData = RequestTestDefaults.defaultModelJSONData
//    private let defaultRequest: Request<DefaultModel, MockBackendServiceError> = RequestTestDefaults.defaultRequest()
//    private var defaultHTTPRequest: HTTP.Request { HTTP.Request(urlRequest: defaultRequest.urlRequest) }
//    private let analyticsRequest: Request<DefaultModel, MockAnalyticsServiceError> = RequestTestDefaults.analyticsRequest()
//
//    // MARK: - Tests
//    func test_FailingRequestAlsoThrows() async {
//        let failure = TransportFailure(error: TransportError(code: .noInternetConnection),
//                                       request: defaultHTTPRequest,
//                                       response: nil)
//        let error = await evaluateThrowingRequest(failure)
//        XCTAssertNil(error)
//    }
//
//    func test_FailingRequestThrowsDifferentError() async {
//        let failure = TransportFailure(error: TransportError(clientError: TestDecodingError.keyNotFound),
//                                       request: defaultHTTPRequest,
//                                       response: nil)
//        let error = await evaluateThrowingRequest(failure) as? TestDecodingError
//        XCTAssertEqual(error, TestDecodingError.keyNotFound)
//    }
//
//    func test_FailingBackendRequest() async {
//        let backendFailure = TransportFailure(error: TransportError(code: .noInternetConnection),
//                                              request: defaultHTTPRequest,
//                                              response: nil)
//
//        await executeBackendService(mockRequest: defaultRequest,
//                                    mockedTransportResult: TransportResult.failure(backendFailure),
//                                    expectingResult: .failure(MockBackendServiceError(transportFailure: backendFailure)))
//
//        await executeBackendService(mockRequest: analyticsRequest,
//                                    mockedTransportResult: TransportResult.failure(backendFailure),
//                                    expectingResult: .failure(MockAnalyticsServiceError(transportFailure: backendFailure)))
//    }
//
//    func test_SuccessfulResultAlsoSucceeds() async throws {
//        let success = TransportSuccess(response: HTTP.Response(request: defaultHTTPRequest,
//                                                               code: 200,
//                                                               body: defaultModelJSONData))
//
//        let result = try await executeBackendRequest(expectedResult: .success(success))
//        XCTAssert(result.title == "test")
//    }
//
//    // MARK: - Private Helpers
//    fileprivate func evaluateThrowingRequest(_ failure: TransportFailure) async -> Error? {
//        do {
//            _ = try await executeBackendRequest(expectedResult: .failure(failure))
//            XCTFail("Expected to throw while awaiting, but succeeded")
//        } catch {
//            let backendError = error as? MockBackendServiceError
//            return backendError?.transportError?.underlyingError
//        }
//
//        return nil
//    }
//
//    private func executeBackendService<T: Equatable, U: Equatable>(mockRequest: Request<T, U>,
//                                                                   mockedTransportResult: TransportResult,
//                                                                   expectingResult expectedResult: Result<T, U>,
//                                                                   file: StaticString = #file,
//                                                                   line: UInt = #line) async {
//        let mockTransportService = MockTransportService(responseResult: mockedTransportResult)
//        let backendService = BackendService(transportService: mockTransportService)
//
//        let result = await backendService.executeWithResult(request: mockRequest)
//
//        switch (result, expectedResult) {
//        case (.success(let resultObject), .success(let expectedObject)):
//            XCTAssertEqual(resultObject, expectedObject, file: file, line: line)
//        case (.failure(let resultError), .failure(let expectedError)):
//            XCTAssertEqual(resultError, expectedError, file: file, line: line)
//        default:
//            XCTFail("Result '\(result)' not equal to expected result '\(expectedResult)'", file: file, line: line)
//        }
//
//        XCTAssertEqual(mockTransportService.lastExecutedURLRequest, mockRequest.urlRequest, file: file, line: line)
//    }
//
//    private func executeBackendRequest(expectedResult: TransportResult,
//                                       file: StaticString = #file,
//                                       line: UInt = #line) async throws -> DefaultModel {
//        let transportService = MockTransportService(responseResult: expectedResult)
//        let backendService = BackendService(transportService: transportService)
//
//        return try await backendService.execute(request: defaultRequest)
//    }
//}

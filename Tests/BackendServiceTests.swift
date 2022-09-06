//
//  BackendServiceTests.swift
//  Tests
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class BackendServiceTests: XCTestCase {

    // MARK: - Typealias

    typealias DefaultModel = RequestTestDefaults.DefaultModel

    // MARK: - Properties

    private let modelJSONData = RequestTestDefaults.defaultModelJSONData
    private let defaultRequest: Request<DefaultModel> = RequestTestDefaults.defaultRequest()
    private lazy var defaultHTTPRequest = HTTP.Request(urlRequest: defaultRequest.urlRequest)
    private lazy var defaultSuccessResponse = HTTP.Response(request: defaultHTTPRequest, code: 200, body: modelJSONData)
    private lazy var defaultFailureResponse = HTTP.Response(request: defaultHTTPRequest, code: 500)

    // MARK: - Tests

    func test_TransportSuccess_TransformsResponseCorrectly() async throws {
        let model = RequestTestDefaults.defaultModel
        let mockedResult = TransportSuccess(response: defaultSuccessResponse)

        try await executeBackendService(mockedTransportResult: .success(mockedResult),
                                        expectingResult: model,
                                        expectingError: nil)
    }

    func test_TransportResponseTransformFailure_GeneratesDataTransformationError() async throws {
        let invalidJSONData = "test".data(using: .utf8)!
        let response = HTTP.Response(request: defaultHTTPRequest, code: 200, body: invalidJSONData)
        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "The given data was not valid JSON."))
        let mockedResult = TransportSuccess(response: response)

        try await executeBackendService(mockedTransportResult: .success(mockedResult),
                                        expectingResult: nil,
                                        expectingError: decodingError)
    }

    func test_TransportNetworkFailure_GeneratesNetworkError() async throws {
        let response = HTTP.Response(request: HTTP.Request(), code: 503, body: nil)
        let mockedResult = TransportFailure(kind: .serverError(.serviceUnavailable), response: response)

        try await executeBackendService(mockedTransportResult: .failure(mockedResult),
                                        expectingResult: nil,
                                        expectingError: mockedResult)
    }

    func test_ExecutingBackendService_ExecutesUnderlyingTransport() async throws {
        let mockedResult = TransportSuccess(response: defaultSuccessResponse)
        let mockTransportService = MockTransportService(responseResult: .success(mockedResult))

        let backendService = BackendService(transportService: mockTransportService)
        _ = try await backendService.execute(request: defaultRequest)

        XCTAssertEqual(mockTransportService.executeCallCount, 1)
    }

    //    func test_CancellingBackendService_CancelsUnderlyingTransportService() {
    //        let mockedResult = TransportSuccess(response: defaultSuccessResponse)
    //        let mockTransportService = MockTransportService(responseResult: .success(mockedResult))
    //
    //        let backendService = BackendService(transportService: mockTransportService)
    //        let request = URLRequest(url: RequestTestDefaults.defaultURL)
    //        backendService.cancelTask(for: request)
    //
    //        XCTAssertEqual(mockTransportService.cancelCallCount, 1)
    //        XCTAssertEqual(mockTransportService.lastCancelledURLRequest, request)
    //    }
    //
    //    func test_BackendServiceDeinit_CancelsAllTasksForUnderlyingTransportService() {
    //        let mockedResult = TransportSuccess(response: defaultSuccessResponse)
    //        let mockTransportService = MockTransportService(responseResult: .success(mockedResult))
    //
    //        var backendService: BackendService? = BackendService(transportService: mockTransportService)
    //        backendService = nil
    //        XCTAssertNil(backendService) // To silence the "variable was written to, but never read" warning. See https://stackoverflow.com/a/32861678/4343618
    //
    //        XCTAssertEqual(mockTransportService.cancelAllTasksCallCount, 1)
    //    }

    func test_BackendService_DefaultsToEmptyArrayOfRecoveryStrategies() {
        let service = MockBackendService()
        XCTAssertTrue(service.recoveryStrategies.isEmpty)
    }

    func test_BackendService_RequestRecoveryTransformerAllowsForMappingTransportFailureToSuccess() async throws {
        let mockedResult = TransportFailure(kind: .serverError(.internalServerError), response: defaultFailureResponse)
        let recoveredResponse = defaultSuccessResponse
        let mockTransportService = MockTransportService(responseResult: .failure(mockedResult))
        let backendService = BackendService(transportService: mockTransportService)

        var request = defaultRequest
        request.recoveryTransformer = { _ in
            return TransportSuccess(response: recoveredResponse)
        }

        let result = try await backendService.execute(request: request)
        XCTAssertNotNil(result)
    }

    func test_BackendService_RequestDefaultRecoveryHandlerWillNotRecoverFromReceivedTransportFailure() async throws {
        let mockedResult = TransportFailure(kind: .serverError(.internalServerError), request: defaultHTTPRequest, response: defaultFailureResponse)
        let mockTransportService = MockTransportService(responseResult: .failure(mockedResult))
        let backendService = BackendService(transportService: mockTransportService)

        let request: Request<MockObject> = .init(method: .get, url: RequestTestDefaults.defaultURL)
        await XCTAssertThrowsError(try await backendService.execute(request: request))
    }

    func test_BackendService_RequestRecoveryHandlerNotCalledWhenTransportSuccessReceived() async throws {
        let mockedResult = TransportSuccess(response: defaultSuccessResponse)
        let mockTransportService = MockTransportService(responseResult: .success(mockedResult))
        let backendService = BackendService(transportService: mockTransportService)

        var request = defaultRequest
        request.recoveryTransformer = { _ in
            return nil
        }

        let result = try await backendService.execute(request: request)
        XCTAssertNotNil(result)
    }

    // MARK: - Private

    private func executeBackendService(mockedTransportResult: TransportResult,
                                       expectingResult expectedResult: DefaultModel?,
                                       expectingError expectedError: Error?,
                                       file: StaticString = #file,
                                       line: UInt = #line) async throws {
        let mockTransportService = MockTransportService(responseResult: mockedTransportResult)
        let backendService = BackendService(transportService: mockTransportService)

        let request = defaultRequest

        do {
            let result = try await backendService.execute(request: request)

            XCTAssertEqual(expectedResult, result)
        } catch {
            XCTAssertEqual(expectedError?.localizedDescription, error.localizedDescription)
        }

        XCTAssertEqual(mockTransportService.lastExecutedURLRequest, request.urlRequest, file: file, line: line)
    }
}

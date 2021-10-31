//
//  AsyncTests.swift
//  Hyperspace-iOS
//
//  Created by Daniel Larsen on 10/30/21.
//  Copyright © 2021 Bottle Rocket Studios. All rights reserved.
//

import Hyperspace
import XCTest

@available(iOS 13.0.0, *)
class AsyncTests: XCTestCase {

    // MARK: - Type Aliases
    typealias DefaultModel = RequestTestDefaults.DefaultModel

    // MARK: - Properties
    private let defaultModelJSONData = RequestTestDefaults.defaultModelJSONData
    private let defaultRequest: Request<DefaultModel, MockBackendServiceError> = RequestTestDefaults.defaultRequest()
    private var defaultHTTPRequest: HTTP.Request { HTTP.Request(urlRequest: defaultRequest.urlRequest) }

    // MARK: - Tests
    func test_FailingRequestAlsoThrows() async {
        let failure = TransportFailure(error: TransportError(code: .noInternetConnection),
                                       request: defaultHTTPRequest, response: nil)
        do {
            _ = try await executeBackendRequest(expectedResult: .failure(failure))
            XCTFail("Expected to throw while awaiting, but succeeded")
        } catch {
            XCTAssertEqual(error as? MockBackendServiceError, .networkError(TransportError(code: .noInternetConnection), nil))
        }
    }

    func test_SuccessfulResultAlsoSucceeds() async throws {
        let success = TransportSuccess(response: HTTP.Response(request: defaultHTTPRequest,
                                                               code: 200,
                                                               body: defaultModelJSONData))

        let result = try await executeBackendRequest(expectedResult: .success(success))
        XCTAssert(result.title == "test")
    }

    // MARK: - Private Helpers
    private func executeBackendRequest(expectedResult: TransportResult, file: StaticString = #file, line: UInt = #line) async throws -> DefaultModel {
        let transportService = MockTransportService(responseResult: expectedResult)
        let backendService = BackendService(transportService: transportService)

        return try await backendService.execute(request: defaultRequest)
    }
}

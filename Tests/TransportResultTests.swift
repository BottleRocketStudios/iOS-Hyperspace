//
//  TransportResultTests.swift
//  Hyperspace
//
//  Created by Will McGinty on 8/19/20.
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class TransportResultTests: XCTestCase {

    private let defaultRequest = URLRequest(url: RequestTestDefaults.defaultURL)
    private lazy var defaultHTTPRequest = HTTP.Request(urlRequest: defaultRequest)

    func test_TransportResult_RetrieveHTTPRequestFromSuccess() {
        let response = HTTP.Response(request: defaultHTTPRequest, code: 200,
                                     url: RequestTestDefaults.defaultURL, headers: ["content-type": "application/json"], body: Data([1, 2, 3, 4]))
        let success = TransportSuccess(response: response)
        let result = TransportResult.success(success)

        XCTAssertEqual(result.request, defaultHTTPRequest)
    }

    func test_TransportResult_RetrieveHTTPResponseFromSuccess() {
        let response = HTTP.Response(request: defaultHTTPRequest, code: 200,
                                     url: RequestTestDefaults.defaultURL, headers: ["content-type": "application/json"], body: Data([1, 2, 3, 4]))
        let success = TransportSuccess(response: response)
        let result = TransportResult.success(success)

        XCTAssertEqual(result.response, response)
    }

    func test_TransportResult_RetrieveHTTPRequestFromFailure() {
        let response = HTTP.Response(request: defaultHTTPRequest, code: 400,
                                     url: RequestTestDefaults.defaultURL, headers: ["content-type": "application/json"], body: Data([1, 2, 3, 4]))
        let failure = TransportFailure(code: .clientError(.badRequest), response: response)
        let result = TransportResult.failure(failure)

        XCTAssertEqual(result.request, defaultHTTPRequest)
    }

    func test_TransportResult_RetrieveHTTPResponseFromFailure() {
        let response = HTTP.Response(request: defaultHTTPRequest, code: 400,
                                     url: RequestTestDefaults.defaultURL, headers: ["content-type": "application/json"], body: Data([1, 2, 3, 4]))
        let failure = TransportFailure(code: .clientError(.badRequest), response: response)
        let result = TransportResult.failure(failure)

        XCTAssertEqual(result.response, response)
    }
}

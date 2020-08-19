//
//  AnyErrorTests.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 5/15/20.
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class AnyErrorTests: XCTestCase {

    struct MockError: Swift.Error, LocalizedError, Equatable {

        var errorDescription: String?
        var failureReason: String?
        var helpAnchor: String?
        var recoverySuggestion: String?
    }

    func test_AnyError_CreatesSuccessfullyFromTransportFailure() {
        let failure = TransportFailure(error: .init(code: .noInternetConnection), request: HTTP.Request(), response: nil)
        let anyError = AnyError(transportFailure: failure)

        XCTAssertTrue(anyError.error is TransportFailure)
        XCTAssertEqual((anyError.error as! TransportFailure).error, TransportError(code: .noInternetConnection))
    }

    func test_AnyError_DoesNotNestAnyErrorInstances() {
        let error = MockError(errorDescription: "description", failureReason: "failureReason", helpAnchor: "helpAnchor", recoverySuggestion: "recoverySuggestion")
        let anyError = AnyError(error)
        let anyError2 = AnyError(anyError)

        XCTAssertTrue(anyError2.error is MockError)
    }

    func test_AnyError_SuccessfullyMaintainsLocalizedErrorInformation() {
        let error = MockError(errorDescription: "description", failureReason: "failureReason", helpAnchor: "helpAnchor", recoverySuggestion: "recoverySuggestion")
        let anyError = AnyError(error)

        XCTAssertEqual(anyError.errorDescription, error.errorDescription)
        XCTAssertEqual(anyError.failureReason, error.failureReason)
        XCTAssertEqual(anyError.helpAnchor, error.helpAnchor)
        XCTAssertEqual(anyError.recoverySuggestion, error.recoverySuggestion)
    }
}

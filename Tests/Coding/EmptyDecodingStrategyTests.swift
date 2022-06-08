//
//  EmptyDecodingStrategyTests.swift
//  Tests
//
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class EmptyDecodingStrategyTests: XCTestCase {

    // MARK: - EmptyError
    enum EmptyDecodingError: Error {
        case unexpectedNonEmptyResponse
    }

    func test_EmptyDecodingStrategy_defaultStrategyAlwaysReturnsEmptyResponse() async throws {
        let transformer = Request<Void>.successTransformer(for: .default)

        let success1 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: Data([1, 2, 3, 4])))
        await XCTAssertNoThrow(try await transformer(success1))

        let success2 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: Data()))
        await XCTAssertNoThrow(try await transformer(success2))

        let success3 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: nil))
        await XCTAssertNoThrow(try await transformer(success3))
    }

    func test_EmptyDecodingStrategy_validatedEmptyStrategyReturnsEmptyResponseForNilOrEmptyData() async throws {
        let transformer = Request<Void>.successTransformer(for: .validatedEmpty(throwing: { _ in EmptyDecodingError.unexpectedNonEmptyResponse }))

        let success1 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: Data([1, 2, 3, 4])))
        await XCTAssertThrowsError(try await transformer(success1))

        let success2 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: Data()))
        await XCTAssertNoThrow(try await transformer(success2))

        let success3 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: nil))
        await XCTAssertNoThrow(try await transformer(success3))
    }

    func test_EmptyDecodingStrategy_CustomStrategyUtilizesHandler() async throws {
        let transportFailure = TransportFailure(kind: .serverError(.badGateway), request: .init(), response: HTTP.Response(request: .init(), code: 502))
        let emptyDecodingStrategy = Request<Void>.EmptyDecodingStrategy { _ in throw transportFailure }

        do {
            let success = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: Data()))
            try await emptyDecodingStrategy.transformer(success)
            
        } catch {
            let thrownTransportFailure = try XCTUnwrap(error as? TransportFailure)
            XCTAssertEqual(thrownTransportFailure, transportFailure)
        }
    }
}

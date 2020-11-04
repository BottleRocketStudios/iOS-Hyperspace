//
//  EmptyDecodingStrategyTests.swift
//  Hyperspace
//
//  Created by Will McGinty on 8/19/20.
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class EmptyDecodingStrategyTests: XCTestCase {

    func test_EmptyDecodingStrategy_defaultStrategyAlwaysReturnsEmptyResponse() {
        let transformer = Request<EmptyResponse, AnyError>.successTransformer(for: .default)

        let success1 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: Data([1, 2, 3, 4])))
        XCTAssertTrue(transformer(success1).isSuccess)

        let success2 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: Data()))
        XCTAssertTrue(transformer(success2).isSuccess)

        let success3 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: nil))
        XCTAssertTrue(transformer(success3).isSuccess)
    }

    func test_EmptyDecodingStrategy_validatedEmptyStrategyReturnsEmptyResponseForNilOrEmptyData() {
        let transformer = Request<EmptyResponse, AnyError>.successTransformer(for: .validatedEmpty)

        let success1 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: Data([1, 2, 3, 4])))
        XCTAssertTrue(transformer(success1).isFailure)

        let success2 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: Data()))
        XCTAssertTrue(transformer(success2).isSuccess)

        let success3 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: nil))
        XCTAssertTrue(transformer(success3).isSuccess)
    }

    func test_EmptyDecodingStrategy_ErrorTransformerYieldsSameResultAsDecodingFailureRepresentableConformance() {
        let transformer = Request<EmptyResponse, AnyError>.successTransformer(for: .validatedEmpty)
        let transformer2 = Request<EmptyResponse, AnyError>.successTransformer(for: .validatedEmpty, decodingFailureTransformer: AnyError.init)

        let success1 = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: Data()))
        XCTAssertTrue(transformer(success1).isSuccess)
        XCTAssertTrue(transformer2(success1).isSuccess)
    }

    func test_EmptyDecodingStrategy_CustomStrategyUtilizesHandler() {
        let error = AnyError(transportFailure: TransportFailure(code: .unknownError, request: HTTP.Request(), response: nil))
        let transformer = Request<EmptyResponse, AnyError>.EmptyDecodingStrategy.custom { _ -> Request<EmptyResponse, AnyError>.Transformer in
            return { _ in .failure(error) }
        }

        let success = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: Data()))
        let result = transformer.transformer(using: AnyError.init)(success)

        switch result {
        case .success: XCTFail("This empty decoding attempt should fail")
        case .failure(let error):
            XCTAssertEqual(error.transportError?.code, .unknownError)
        }
    }
}

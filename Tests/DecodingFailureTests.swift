//
//  DecodingFailureTests.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 8/27/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class DecodingFailureTests: XCTestCase {
    
    private struct MockDecodeError: DecodingFailureRepresentable {
        var transportError: TransportError?
        var decodingFailure: DecodingFailure?
        var failureResponse: HTTP.Response?

        init(transportFailure: TransportFailure) {
            transportError = transportFailure.error
            failureResponse = transportFailure.response
        }

        init(decodingFailure: DecodingFailure) {
            self.decodingFailure = decodingFailure
            self.failureResponse = decodingFailure.response
        }
    }

    func test_DecodingFailure_ReturnsNonOptionalResponseFromUnderlyingCase() {
        let response = HTTP.Response(request: HTTP.Request(), code: 200, body: Data([1, 2, 3, 4]))
        let failure = DecodingFailure.invalidEmptyResponse(response)
        let failure2 = DecodingFailure.decodingError(.init(decodingError: DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "")),
                                                           failingType: MockObject.self, response: response))

        XCTAssertEqual(failure.response, response)
        XCTAssertEqual(failure2.response, response)
    }

    func test_DecodingFailure_ReturnsOptionalDecodingContextFromUnderlyingCase() {
        let response = HTTP.Response(request: HTTP.Request(), code: 200, body: Data([1, 2, 3, 4]))
        let failure = DecodingFailure.invalidEmptyResponse(response)
        let context = DecodingFailure.Context(decodingError: DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "")),
                                              failingType: MockObject.self, response: response)
        let failure2 = DecodingFailure.decodingError(context)

        XCTAssertNil(failure.decodingContext)
        XCTAssertNotNil(failure2.decodingContext)
        XCTAssertEqual(failure2.decodingContext?.response, context.response)
    }

    func test_DecodingFailure_GenericFailureTranslatesToDecodingError() {
        let response = HTTP.Response(request: HTTP.Request(), code: 200, body: Data([1, 2, 3, 4]))
        let failure = DecodingFailure.genericFailure(decoding: MockObject.self, from: response, debugDescription: "debug description")

        XCTAssertEqual(failure.decodingContext?.response, response)
    }
    
    func test_DecodingFailure_CatchesFailedTypeInformation() {
        let objectJSON = loadedJSONData(fromFileNamed: "DateObject")

        let transformer = Request<MockCodableContainer, MockDecodeError>.successTransformer(for: JSONDecoder())
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let result = transformer(serviceSuccess)
        
        guard let error = result.error else { return XCTFail("The decode should fail.") }
        XCTAssertEqual(error.failureResponse?.body, objectJSON)

        guard let failingType = error.decodingFailure?.decodingContext?.failingType else { return XCTFail("The decoding should fail because the JSONDecoder failed.") }
        XCTAssertEqual(String(describing: failingType), String(describing: MockCodableContainer.self))
    }
}

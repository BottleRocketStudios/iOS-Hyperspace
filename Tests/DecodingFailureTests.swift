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

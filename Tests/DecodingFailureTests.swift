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
        var failureResponse: HTTP.Response?
        
        var error: DecodingError?
        var type: Decodable.Type?
        var response: HTTP.Response?

        init(transportFailure: TransportFailure) {
            transportError = transportFailure.error
            failureResponse = transportFailure.response
        }
        
        init(error: DecodingError, decoding: Decodable.Type, response: HTTP.Response) {
            self.error = error
            self.type = decoding
            self.response = response
        }
    }
    
    func test_DecodingFailure_CatchesFailedTypeInformation() {
        let objectJSON = loadedJSONData(fromFileNamed: "DateObject")

        let transformer = Request<MockCodableContainer, MockDecodeError>.successTransformer(for: JSONDecoder())
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let result = transformer(serviceSuccess)
        
        guard let error = result.error else { return XCTFail("The decode should fail.") }
        guard let type = error.type else { return XCTFail("The decoding failure should detect the failed type information") }
        XCTAssertEqual(String(describing: type), String(describing: MockCodableContainer.self))
        XCTAssertEqual(error.response?.body, objectJSON)
    }
}

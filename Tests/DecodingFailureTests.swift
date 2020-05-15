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
        var transportError: TransportError = .init(code: .unknownError)
        var failureResponse: HTTP.Response?
        
        let error: DecodingError
        let type: Decodable.Type
        let response: HTTP.Response
        
        // TODO: Do they need to be dependent on one another?
        init(transportFailure: TransportFailure) {
            fatalError()
            /* No op - unused for test */
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
        let serviceSuccess = TransportSuccess(response: HTTP.Response(code: 200, data: objectJSON))
        let result = transformer(serviceSuccess)
        
        guard let error = result.error else { XCTFail("The decode should fail."); return }
        XCTAssertEqual(String(describing: error.type), String(describing: MockCodableContainer.self))
        XCTAssertEqual(error.response.data, objectJSON)
    }
}

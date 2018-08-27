//
//  DecodingFailureTests.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 8/27/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace
import Result

class DecodingFailureTests: XCTestCase {
    
    private struct MockDecodeError: DecodingFailureInitializable {
        
        let error: DecodingError
        let type: Decodable.Type
        let data: Data
        
        init(decodingError: DecodingError, decoding: Decodable.Type, data: Data) {
            self.error = decodingError
            self.type = decoding
            self.data = data
        }
    }
    
    func test_DecodingFailure_CatchesFailedTypeInformation() {
        let objectJSON = loadedJSONData(fromFileNamed: "DateObject")

        let transformer: (Data) -> Result<MockDecodableContainer, MockDecodeError> = RequestDefaults.dataTransformer(for: JSONDecoder())
        let result = transformer(objectJSON)
        
        XCTAssertNotNil(result.error)
        XCTAssertEqual(String(describing: result.error?.type), "Optional(Hyperspace_iOSTests.MockDecodableContainer)")
        XCTAssertEqual(result.error?.data, objectJSON)
    }
    
    // MARK: - Helper
    
    private func loadedJSONData(fromFileNamed name: String) -> Data {
        let bundle = Bundle(for: DecodingTests.self)
        let url = bundle.url(forResource: name, withExtension: "json")!
        return try! Data(contentsOf: url)
    }
}

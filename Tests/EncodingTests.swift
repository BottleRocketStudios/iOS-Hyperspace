//
//  EncodingTests.swift
//  Hyperspace-iOS
//
//  Created by William McGinty on 5/14/20.
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class EncodingTests: XCTestCase {
    
    // MARK: - Tests
    
    func test_JSONEncoder_properlyEncodesTypeInsideContainer() {
        let mockObject = MockObject(title: "Title", subtitle: "Subtitle")
        do {
            let encoder = JSONEncoder()
            let objectJSON = try encoder.encode(mockObject, in: MockCodableContainer.self)
            
            let decoder = JSONDecoder()
            let element: MockObject = try decoder.decode(from: objectJSON, with: MockCodableContainer.self)
            XCTAssertEqual(element.title, mockObject.title)
            XCTAssertEqual(element.subtitle, mockObject.subtitle)
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}

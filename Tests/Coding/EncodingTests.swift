//
//  EncodingTests.swift
//  Tests
//
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class EncodingTests: XCTestCase {

    // MARK: - Tests
    func test_JSONEncoder_properlyEncodesTypeInsideContainer() throws {
        let mockObject = MockObject(title: "Title", subtitle: "Subtitle")
        
        let encoder = JSONEncoder()
        let objectJSON = try encoder.encode(mockObject, in: MockCodableContainer.self)

        let decoder = JSONDecoder()
        let element: MockObject = try decoder.decode(from: objectJSON, with: MockCodableContainer.self)
        XCTAssertEqual(element.title, mockObject.title)
        XCTAssertEqual(element.subtitle, mockObject.subtitle)
    }
}

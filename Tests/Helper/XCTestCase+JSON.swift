//
//  XCTestCase+JSON.swift
//  Tests
//
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import XCTest

extension XCTestCase {
    
    func loadedJSONData(fromFileNamed name: String) -> Data {
        let bundle = Bundle(for: DecodingTests.self)
        let url = bundle.url(forResource: name, withExtension: "json")!
        return try! Data(contentsOf: url)
    }
}

//
//  XCTestCase+JSON.swift
//  Tests
//
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import XCTest

extension XCTestCase {
    
    func loadedJSONData(fromFileNamed name: String) -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "json")!
        return try! Data(contentsOf: url)
    }
}

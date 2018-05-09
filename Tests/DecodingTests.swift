//
//  DecodableContainerTests.swift
//  Hyperspace_Example
//
//  Created by Will McGinty on 12/5/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace
import Result

class DecodingTests: XCTestCase {
    
    // MARK: - Properties
    
    private static let iso8601DateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    
    // MARK: - Tests
    
    func test_DecodingDecodableContainer_AutomaticallyDecodesChildElement() {
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        do {
            let decoder = JSONDecoder()
            let container = try decoder.decode(MockDecodableContainer.self, from: objectJSON)
            let child = container.element
            XCTAssertEqual(child.title, "Title")
            XCTAssertEqual(child.subtitle, "Subtitle")
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_DecodingDecodableContainer_AutomaticallyDecodesChildElements() {
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        do {
            let decoder = JSONDecoder()
            let container = try decoder.decode(MockArrayDecodableContainer.self, from: objectJSON)
            let children = container.element
            
            for index in children.startIndex..<children.endIndex {
                let child = children[index]
                XCTAssertEqual(child.title, "Title \(index)")
                XCTAssertEqual(child.subtitle, "Subtitle \(index)")
            }
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_AnyNetworkRequestWithDefaultJSONDecoder_SuccessfullyDecodes() {
        let request = AnyNetworkRequest<MockObject>(method: .get, url: NetworkRequestTestDefaults.defaultURL, decoder: JSONDecoder())
        let objectJSON = loadedJSONData(fromFileNamed: "Object")
        let result = request.transformData(objectJSON)
        XCTAssertNotNil(result.value)
    }
    
    func test_AnyNetworkRequestWithImplicitJSONDecoder_SuccessfullyDecodes() {
        let request = AnyNetworkRequest<MockObject>(method: .get, url: NetworkRequestTestDefaults.defaultURL)
        let objectJSON = loadedJSONData(fromFileNamed: "Object")
        let result = request.transformData(objectJSON)
        XCTAssertNotNil(result.value)
    }
    
    func test_AnyNetworkRequestWithISOJSONDecoder_SuccessfullyDecodes() {
        let decoder = JSONDecoder()
        
        if #available(iOS 10.0, *) {
            decoder.dateDecodingStrategy = .iso8601
        } else {
            decoder.dateDecodingStrategy = .formatted(DecodingTests.iso8601DateFormatter)
        }
        
        let request = AnyNetworkRequest<MockDate>(method: .get, url: NetworkRequestTestDefaults.defaultURL, decoder: decoder)
        let objectJSON = loadedJSONData(fromFileNamed: "DateObject")
        let result = request.transformData(objectJSON)
        XCTAssertNotNil(result.value)
    }
    
    func test_AnyNetworkRequestWithImplicitJSONDecoder_DecodeFails() {
        let request = AnyNetworkRequest<MockDate>(method: .get, url: NetworkRequestTestDefaults.defaultURL)
        let objectJSON = loadedJSONData(fromFileNamed: "DateObject")
        let result = request.transformData(objectJSON)
        XCTAssertNil(result.value)
    }
    
    func test_AnyNetworkRequesWithDecodableContainer_SuccessfullyDecodesChildElement() {
        let request = AnyNetworkRequest<MockObject>(method: .get, url: NetworkRequestTestDefaults.defaultURL, containerType: MockDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        let result = request.transformData(objectJSON)
        XCTAssertNotNil(result.value)
    }

    func test_AnyNetworkRequesWithDecodableContainer_SuccessfullyDecodesChildElements() {
        let request = AnyNetworkRequest<[MockObject]>(method: .get, url: NetworkRequestTestDefaults.defaultURL, containerType: MockArrayDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let result = request.transformData(objectJSON)
        XCTAssertNotNil(result.value)
    }
    
    func test_AnyNetworkRequesWithDecodableContainer_FailsToDecodesChildElement() {
        let request = AnyNetworkRequest<MockObject>(method: .get, url: NetworkRequestTestDefaults.defaultURL, containerType: MockDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let result = request.transformData(objectJSON)
        XCTAssertNil(result.value) //Should fail because RootKeyArray json contains [MockObject], not a single MockObject
    }

    private func loadedJSONData(fromFileNamed name: String) -> Data {
        let bundle = Bundle(for: DecodingTests.self)
        let url = bundle.url(forResource: name, withExtension: "json")!
        return try! Data(contentsOf: url)
    }
}

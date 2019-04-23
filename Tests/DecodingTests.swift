//
//  DecodableContainerTests.swift
//  Hyperspace_Example
//
//  Created by Will McGinty on 12/5/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

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
    
    func test_RequestDefaultsContainer_AutomaticallyDecodesChildElement() {
        let function: RequestTransformBlock<MockObject, AnyError> = RequestDefaults.successTransformer(for: JSONDecoder(), withContainerType: MockDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        let serviceSuccess = NetworkServiceSuccess(data: objectJSON, response: HTTP.Response(code: 200, data: objectJSON))
        let mockObject = function(serviceSuccess)
        XCTAssertNotNil(mockObject.value)
    }
    
    func test_RequestDefaultsContainer_AutomaticallyDecodesChildElements() {
        let function: RequestTransformBlock<[MockObject], AnyError> = RequestDefaults.successTransformer(for: JSONDecoder(), withContainerType: MockArrayDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let serviceSuccess = NetworkServiceSuccess(data: objectJSON, response: HTTP.Response(code: 200, data: objectJSON))
        let mockObject = function(serviceSuccess)
        XCTAssertNotNil(mockObject.value)
    }
    
    func test_RequestDefaultsContainer_ThrowsErrorForChildElement() {
        let function: RequestTransformBlock<MockObject, AnyError> = RequestDefaults.successTransformer(for: JSONDecoder(), withContainerType: MockDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let serviceSuccess = NetworkServiceSuccess(data: objectJSON, response: HTTP.Response(code: 200, data: objectJSON))
        let mockObject = function(serviceSuccess)
        XCTAssertNotNil(mockObject.error)
    }
    
    func test_RequestDefaultsContainer_ThrowsErrorForChildElements() {
        let function: RequestTransformBlock<[MockObject], AnyError> = RequestDefaults.successTransformer(for: JSONDecoder(), withContainerType: MockArrayDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        let serviceSuccess = NetworkServiceSuccess(data: objectJSON, response: HTTP.Response(code: 200, data: objectJSON))
        let mockObject = function(serviceSuccess)
        XCTAssertNotNil(mockObject.error)
    }
    
    func test_AnyRequestWithDefaultJSONDecoder_SuccessfullyDecodes() {
        let request = AnyRequest<MockObject>(method: .get, url: RequestTestDefaults.defaultURL, decoder: JSONDecoder())
        let objectJSON = loadedJSONData(fromFileNamed: "Object")
        let serviceSuccess = NetworkServiceSuccess(data: objectJSON, response: HTTP.Response(code: 200, data: objectJSON))
        let result = request.transformSuccess(serviceSuccess)
        XCTAssertNotNil(result.value)
    }
    
    func test_AnyRequestWithImplicitJSONDecoder_SuccessfullyDecodes() {
        let request = AnyRequest<MockObject>(method: .get, url: RequestTestDefaults.defaultURL)
        let objectJSON = loadedJSONData(fromFileNamed: "Object")
        let serviceSuccess = NetworkServiceSuccess(data: objectJSON, response: HTTP.Response(code: 200, data: objectJSON))
        let result = request.transformSuccess(serviceSuccess)
        XCTAssertNotNil(result.value)
    }
    
    func test_AnyRequestWithISOJSONDecoder_SuccessfullyDecodes() {
        let decoder = JSONDecoder()
        
        if #available(iOS 10.0, *) {
            decoder.dateDecodingStrategy = .iso8601
        } else {
            decoder.dateDecodingStrategy = .formatted(DecodingTests.iso8601DateFormatter)
        }
        
        let request = AnyRequest<MockDate>(method: .get, url: RequestTestDefaults.defaultURL, decoder: decoder)
        let objectJSON = loadedJSONData(fromFileNamed: "DateObject")
        let serviceSuccess = NetworkServiceSuccess(data: objectJSON, response: HTTP.Response(code: 200, data: objectJSON))
        let result = request.transformSuccess(serviceSuccess)
        XCTAssertNotNil(result.value)
    }
    
    func test_AnyRequestWithImplicitJSONDecoder_DecodeFails() {
        let request = AnyRequest<MockDate>(method: .get, url: RequestTestDefaults.defaultURL)
        let objectJSON = loadedJSONData(fromFileNamed: "DateObject")
        let serviceSuccess = NetworkServiceSuccess(data: objectJSON, response: HTTP.Response(code: 200, data: objectJSON))
        let result = request.transformSuccess(serviceSuccess)
        XCTAssertNil(result.value)
    }
    
    func test_AnyRequestWithDecodableContainer_SuccessfullyDecodesChildElement() {
        let request = AnyRequest<MockObject>(method: .get, url: RequestTestDefaults.defaultURL, containerType: MockDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        let serviceSuccess = NetworkServiceSuccess(data: objectJSON, response: HTTP.Response(code: 200, data: objectJSON))
        let result = request.transformSuccess(serviceSuccess)
        XCTAssertNotNil(result.value)
    }

    func test_AnyRequestWithDecodableContainer_SuccessfullyDecodesChildElements() {
        let request = AnyRequest<[MockObject]>(method: .get, url: RequestTestDefaults.defaultURL, containerType: MockArrayDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let serviceSuccess = NetworkServiceSuccess(data: objectJSON, response: HTTP.Response(code: 200, data: objectJSON))
        let result = request.transformSuccess(serviceSuccess)
        XCTAssertNotNil(result.value)
    }
    
    func test_AnyRequestWithDecodableContainer_FailsToDecodesChildElement() {
        let request = AnyRequest<MockObject>(method: .get, url: RequestTestDefaults.defaultURL, containerType: MockDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let serviceSuccess = NetworkServiceSuccess(data: objectJSON, response: HTTP.Response(code: 200, data: objectJSON))
        let result = request.transformSuccess(serviceSuccess)
        XCTAssertNil(result.value) //Should fail because RootKeyArray json contains [MockObject], not a single MockObject
    }
}

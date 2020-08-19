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
    
    func test_JSONDecoder_properlyDecodesTypeInsideContainer() {
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        do {
            let decoder = JSONDecoder()
            let element: MockObject = try decoder.decode(from: objectJSON, with: MockCodableContainer.self)
            XCTAssertEqual(element.title, "Title")
            XCTAssertEqual(element.subtitle, "Subtitle")
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_DecodingDecodableContainer_AutomaticallyDecodesChildElement() {
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        do {
            let decoder = JSONDecoder()
            let container = try decoder.decode(MockCodableContainer.self, from: objectJSON)
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
        let function = Request<MockObject, AnyError>.successTransformer(for: JSONDecoder(), with: MockCodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")

        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let mockObject = function(serviceSuccess)
        XCTAssertNotNil(mockObject.value)
    }
    
    func test_RequestDefaultsContainer_AutomaticallyDecodesChildElements() {
        let function = Request<[MockObject], AnyError>.successTransformer(for: JSONDecoder(), with: MockArrayDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let mockObject = function(serviceSuccess)
        XCTAssertNotNil(mockObject.value)
    }
    
    func test_RequestDefaultsContainer_ThrowsErrorForChildElement() {
        let function = Request<MockObject, AnyError>.successTransformer(for: JSONDecoder(), with: MockCodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let mockObject = function(serviceSuccess)
        XCTAssertNotNil(mockObject.error)
    }
    
    func test_RequestDefaultsContainer_ThrowsErrorForChildElements() {
        let function = Request<[MockObject], AnyError>.successTransformer(for: JSONDecoder(), with: MockArrayDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let mockObject = function(serviceSuccess)
        XCTAssertNotNil(mockObject.error)
    }
    
    func test_RequestWithDefaultJSONDecoder_SuccessfullyDecodes() {
        let request = Request<MockObject, AnyError>(method: .get, url: RequestTestDefaults.defaultURL, decoder: JSONDecoder())
        let objectJSON = loadedJSONData(fromFileNamed: "Object")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let result = request.transform(success: serviceSuccess)
        XCTAssertNotNil(result.value)
    }
    
    func test_RequestWithImplicitJSONDecoder_SuccessfullyDecodes() {
        let request = Request<MockObject, AnyError>(method: .get, url: RequestTestDefaults.defaultURL)
        let objectJSON = loadedJSONData(fromFileNamed: "Object")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let result = request.transform(success: serviceSuccess)
        XCTAssertNotNil(result.value)
    }
    
    func test_RequestWithISOJSONDecoder_SuccessfullyDecodes() {
        let decoder = JSONDecoder()
        
        if #available(iOS 10.0, *) {
            decoder.dateDecodingStrategy = .iso8601
        } else {
            decoder.dateDecodingStrategy = .formatted(DecodingTests.iso8601DateFormatter)
        }
        
        let request = Request<MockDate, AnyError>(method: .get, url: RequestTestDefaults.defaultURL, decoder: decoder)
        let objectJSON = loadedJSONData(fromFileNamed: "DateObject")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let result = request.transform(success: serviceSuccess)
        XCTAssertNotNil(result.value)
    }
    
    func test_RequestWithImplicitJSONDecoder_DecodeFails() {
        let request = Request<MockDate, AnyError>(method: .get, url: RequestTestDefaults.defaultURL)
        let objectJSON = loadedJSONData(fromFileNamed: "DateObject")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let result = request.transform(success: serviceSuccess)
        XCTAssertNil(result.value)
    }
    
    func test_RequestWithDecodableContainer_SuccessfullyDecodesChildElement() {
        let request = Request<MockObject, AnyError>(method: .get, url: RequestTestDefaults.defaultURL, containerType: MockCodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let result = request.transform(success: serviceSuccess)
        XCTAssertNotNil(result.value)
    }

    func test_RequestWithDecodableContainer_SuccessfullyDecodesChildElements() {
        let request = Request<[MockObject], AnyError>(method: .get, url: RequestTestDefaults.defaultURL, containerType: MockArrayDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let result = request.transform(success: serviceSuccess)
        XCTAssertNotNil(result.value)
    }
    
    func test_RequestWithDecodableContainer_FailsToDecodesChildElement() {
        let request = Request<MockObject, AnyError>(method: .get, url: RequestTestDefaults.defaultURL, containerType: MockCodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))
        let result = request.transform(success: serviceSuccess)
        XCTAssertNil(result.value) //Should fail because RootKeyArray json contains [MockObject], not a single MockObject
    }
}

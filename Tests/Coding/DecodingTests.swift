//
//  DecodableContainerTests.swift
//  Tests
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class DecodingTests: XCTestCase {

    // MARK: - JSONDecoder Tests
    func test_JSONDecoder_properlyDecodesTypeInsideContainer() throws {
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        let decoder = JSONDecoder()

        let element: MockObject = try decoder.decode(from: objectJSON, with: MockCodableContainer.self)
        XCTAssertEqual(element.title, "Title")
        XCTAssertEqual(element.subtitle, "Subtitle")
    }

    func test_DecodingDecodableContainer_AutomaticallyDecodesChildElement() throws {
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        let decoder = JSONDecoder()

        let container = try decoder.decode(MockCodableContainer.self, from: objectJSON)
        let child = container.element
        XCTAssertEqual(child.title, "Title")
        XCTAssertEqual(child.subtitle, "Subtitle")
    }

    func test_DecodingDecodableContainer_AutomaticallyDecodesChildElements() throws {
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let decoder = JSONDecoder()

        let container = try decoder.decode(MockArrayDecodableContainer.self, from: objectJSON)
        let children = container.element

        for index in children.indices {
            let child = children[index]
            XCTAssertEqual(child.title, "Title \(index)")
            XCTAssertEqual(child.subtitle, "Subtitle \(index)")
        }
    }

    // MARK: - Request Transformer Tests
    func test_RequestWithDefaultJSONDecoder_SuccessfullyDecodes() async throws {
        let request = Request<MockObject>(method: .get, url: RequestTestDefaults.defaultURL, decoder: JSONDecoder())
        let objectJSON = loadedJSONData(fromFileNamed: "Object")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))

        let mockObject = try await request.transform(success: serviceSuccess)
        XCTAssertEqual(mockObject.title, "Title 0")
    }

    func test_RequestWithImplicitJSONDecoder_SuccessfullyDecodes() async throws {
        let request = Request<MockObject>(method: .get, url: RequestTestDefaults.defaultURL)
        let objectJSON = loadedJSONData(fromFileNamed: "Object")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))

        let mockObject = try await request.transform(success: serviceSuccess)
        XCTAssertEqual(mockObject.title, "Title 0")
    }

    func test_RequestWithISOJSONDecoder_SuccessfullyDecodes() async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let request = Request<MockDate>(method: .get, url: RequestTestDefaults.defaultURL, decoder: decoder)
        let objectJSON = loadedJSONData(fromFileNamed: "DateObject")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))

        let mockDate = try await request.transform(success: serviceSuccess)
        XCTAssertEqual(ISO8601DateFormatter().string(from: mockDate.date), "2017-11-13T05:00:00Z")
    }

    func test_RequestWithImplicitJSONDecoder_DecodeFails() async throws {
        let request = Request<MockDate>(method: .get, url: RequestTestDefaults.defaultURL)
        let objectJSON = loadedJSONData(fromFileNamed: "DateObject")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))

        await XCTAssertThrowsError(try await request.transform(success: serviceSuccess))
        // Throws when attempting to decode a date with a time interval
    }

    // MARK: - Request Transformer Tests with DecodableContainer
    func test_RequestDefaultsContainer_AutomaticallyDecodesChildElement() async throws {
        let transformer = Request<MockObject>.successTransformer(for: JSONDecoder(), with: MockCodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))

        let mockObject = try await transformer(serviceSuccess)
        XCTAssertEqual(mockObject.title, "Title")
    }

    func test_RequestDefaultsContainer_AutomaticallyDecodesChildElements() async throws {
        let transformer = Request<[MockObject]>.successTransformer(for: JSONDecoder(), with: MockArrayDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))

        let mockObjects = try await transformer(serviceSuccess)
        XCTAssertEqual(mockObjects.count, 2)
    }

    func test_RequestDefaultsContainer_ThrowsErrorForChildElement() async throws {
        let transformer = Request<MockObject>.successTransformer(for: JSONDecoder(), with: MockCodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))

        await XCTAssertThrowsError(try await transformer(serviceSuccess))
        // Throws when attempting to decode a single object from a JSON array
    }

    func test_RequestDefaultsContainer_ThrowsErrorForChildElements() async throws {
        let transformer = Request<[MockObject]>.successTransformer(for: JSONDecoder(), with: MockArrayDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))

        await XCTAssertThrowsError(try await transformer(serviceSuccess))
        // Throws when attempting to decode an array from a JSON object
    }

    func test_RequestWithDecodableContainer_SuccessfullyDecodesChildElement() async throws {
        let request = Request<MockObject>(method: .get, url: RequestTestDefaults.defaultURL, containerType: MockCodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyObject")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))

        let mockObject = try await request.transform(success: serviceSuccess)
        XCTAssertEqual(mockObject.title, "Title")
    }

    func test_RequestWithDecodableContainer_SuccessfullyDecodesChildElements() async throws {
        let request = Request<[MockObject]>(method: .get, url: RequestTestDefaults.defaultURL, containerType: MockArrayDecodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))

        let mockObjects = try await request.transform(success: serviceSuccess)
        XCTAssertEqual(mockObjects.count, 2)
    }

    func test_RequestWithDecodableContainer_FailsToDecodesChildElement() async throws {
        let request = Request<MockObject>(method: .get, url: RequestTestDefaults.defaultURL, containerType: MockCodableContainer.self)
        let objectJSON = loadedJSONData(fromFileNamed: "RootKeyArray")
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(), code: 200, body: objectJSON))

        await XCTAssertThrowsError(try await request.transform(success: serviceSuccess))
        // Throws when attempting to decode a single object from a JSON array
    }
}

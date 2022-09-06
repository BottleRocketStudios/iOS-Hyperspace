//
//  URLQueryParameterTests.swift
//  Tests
//
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

@available(*, deprecated)
class URLQueryParameterTests: XCTestCase {

    // MARK: - Tests
    func test_DefaultURLQueryEncodingStraegy_GeneratesCorrectURL() {
        let url = RequestTestDefaults.defaultURL
        
        let queryParameters = [
            URLQueryItem(name: "param1", value: "param1value"),
            URLQueryItem(name: "param2", value: "param2 value"),
            URLQueryItem(name: "param3", value: nil)
        ]
        
        let finalURL = url.appendingQueryItems(queryParameters)
        XCTAssertEqual(finalURL.absoluteString, "https://apple.com?param1=param1value&param2=param2%20value&param3")
    }
    
    func testCustomURLQueryEncodingStrategy_GeneratesCorrectURL() {
        let queryParameters = [
            URLQueryItem(name: "param1", value: "param1value"),
            URLQueryItem(name: "param2", value: "param2 value"),
            URLQueryItem(name: "param3", value: nil)
        ]
        
        let url = RequestTestDefaults.defaultURL
        let finalURL = url.appendingQueryItems(queryParameters, using: .customEncoder)
        XCTAssertEqual(finalURL.absoluteString, "https://apple.com?param1=param1value&param2=param2-value&param3")
    }
    
    func testDefaultURLQueryEncodingStrategy_EncodesQueryProperly() {
        let queryString = URLQueryParameterEncoder().encode("this is a test")
        XCTAssertEqual(queryString, "this%20is%20a%20test")
    }
    
    func testCustomURLQueryEncodingStrategy_EncodesQueryProperly() {
        let queryString = URLQueryParameterEncoder.customEncoder.encode("this is a test")
        XCTAssertEqual(queryString, "this-is-a-test")
    }
    
    func testAppendingQueryStringToURLWithNoQueryString() {
        let url = RequestTestDefaults.defaultURL
        let queryString = URLQueryParameterEncoder().encode([URLQueryItem(name: "test", value: "value")])
        
        let final = url.appendingQueryString(queryString)
        XCTAssertEqual(final.absoluteString, "https://apple.com?test=value")
    }
    
    func testAppendingEmptyQueryStringToURLWithNoQueryString() {
        let url = RequestTestDefaults.defaultURL
        let queryString = URLQueryParameterEncoder().encode([])
        
        let final = url.appendingQueryString(queryString)
        XCTAssertEqual(final.absoluteString, "https://apple.com")
    }
    
    func testAppendingEmptyQueryStringToURLWithExistingQueryString() {
        let url = RequestTestDefaults.defaultURL.appendingQueryString("test=value")
        let queryString = URLQueryParameterEncoder().encode([])
        
        let final = url.appendingQueryString(queryString)
        XCTAssertEqual(final.absoluteString, "https://apple.com?test=value")
    }
}

@available(*, deprecated)
fileprivate extension URLQueryParameterEncoder {
    static let customEncoder: URLQueryParameterEncoder = {
        var encoder = URLQueryParameterEncoder()
        encoder.encodingStrategy = .custom { content -> String in
            return content.replacingOccurrences(of: " ", with: "-", options: .literal, range: nil)
        }
        return encoder
    }()
}

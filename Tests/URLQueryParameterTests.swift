//
//  URLQueryParameterTests.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 5/14/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class URLQueryParameterTests: XCTestCase {
    
    func test_DefaultURLQueryEncodingStraegy_GeneratesCorrectURL() {
        let url = NetworkRequestTestDefaults.defaultURL
        
        let queryParameters = [
            URLQueryItem(name: "param1", value: "param1value"),
            URLQueryItem(name: "param2", value: "param2 value"),
            URLQueryItem(name: "param3", value: nil)
            // TODO: What other complex query parameters can we generate to test the URL encoding?
        ]
        
        let finalURL = url.appendingQueryItems(queryParameters, using: .urlQueryAllowedCharacterSet)
        XCTAssertEqual(finalURL.absoluteString, "https://apple.com?param1=param1value&param2=param2%20value&param3")
    }
    
    func testCustomURLQueryEncodingStrategy_GeneratesCorrectURL() {
        let queryParameters = [
            URLQueryItem(name: "param1", value: "param1value"),
            URLQueryItem(name: "param2", value: "param2 value"),
            URLQueryItem(name: "param3", value: nil)
        ]
        
        let url = NetworkRequestTestDefaults.defaultURL
        let finalURL = url.appendingQueryItems(queryParameters, using: .customTest)
        XCTAssertEqual(finalURL.absoluteString, "https://apple.com?param1=param1value&param2=param2-value&param3")
    }
    
    func testDefaultURLQueryEncodingStrategy_EncodesQueryProperly() {
        let queryString = URL.QueryParameterEncodingStrategy.urlQueryAllowedCharacterSet.encode(string: "this is a test")
        XCTAssertEqual(queryString, "this%20is%20a%20test")
    }
    
    func testCustomURLQueryEncodingStrategy_EncodesQueryProperly() {
        let queryString = URL.QueryParameterEncodingStrategy.customTest.encode(string: "this is a test")
        XCTAssertEqual(queryString, "this-is-a-test")
    }
}

fileprivate extension URL.QueryParameterEncodingStrategy {
    static let customTest = URL.QueryParameterEncodingStrategy.custom { content in
        return content.replacingOccurrences(of: " ", with: "-", options: .literal, range: nil)
    }
}

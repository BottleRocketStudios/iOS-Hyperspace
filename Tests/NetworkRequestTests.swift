//
//  NetworkRequestTests.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
import Hyperspace
import Result

class NetworkRequestTests: XCTestCase {
    
    // MARK: - Constants
    
    private static let defaultRequestMethod: HTTP.Method = .get
    private static let defaultURL = URL(string: "http://apple.com")!
    private static let defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    private static let defaultTimeout: TimeInterval = 1.0
    
    // MARK: - NetworkRequest Implementations
    
    public struct SimpleGETRequest: NetworkRequest {
        // swiftlint:disable nesting
        typealias ResponseType = String
        typealias ErrorType = AnyError
        // swiftlint:enable nesting
        
        var method: HTTP.Method = NetworkRequestTests.defaultRequestMethod
        var url = NetworkRequestTests.defaultURL
        var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
        var body: Data?
        var cachePolicy: URLRequest.CachePolicy = NetworkRequestTests.defaultCachePolicy
        var timeout: TimeInterval = NetworkRequestTests.defaultTimeout
    }
    
    struct SimplePOSTRequest: NetworkRequest {
        // swiftlint:disable nesting
        typealias ResponseType = String
        typealias ErrorType = AnyError
        // swiftlint:enable nesting
        
        var method: HTTP.Method = .post
        var url = NetworkRequestTests.defaultURL
        var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
        var body: Data?
        var cachePolicy: URLRequest.CachePolicy = NetworkRequestTests.defaultCachePolicy
        var timeout: TimeInterval = NetworkRequestTests.defaultTimeout
    }
    
    struct CachePolicyAndTimeOutRequest: NetworkRequest {
        // swiftlint:disable nesting
        typealias ResponseType = EmptyResponse
        typealias ErrorType = AnyError
        // swiftlint:enable nesting
        
        var method: HTTP.Method = NetworkRequestTests.defaultRequestMethod
        var url = NetworkRequestTests.defaultURL
        var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
        var body: Data?
    }
    
    // MARK: - Tests
    
    func test_SimpleGETRequestWithoutQueryParametersOrHeaders_GeneratesCorrectURLRequest() {
        let request = SimpleGETRequest()
        assertParameters(for: request)
    }
    
    func test_SimpleGETRequestWithHeaders_GeneratesCorrectURLRequest() {
        var request = SimpleGETRequest()
        request.headers = [.contentType: .applicationJSON]
        
        assertParameters(headers: ["Content-Type": "application/json"], for: request)
    }
    
    func test_SimplePOSTRequestWithData_GeneratesCorrectURLRequest() {
        let bodyData = "Test".data(using: .utf8)!
        
        var request = SimplePOSTRequest()
        request.body = bodyData
        
        assertParameters(method: "POST", body: bodyData, for: request)
    }
    
    func test_NetworkRequest_EmptyResponseInit() {
        _ = EmptyResponse()
        XCTAssert(true)
    }
    
    func test_NetworkRequestWithoutExplicitCachePolicyAndTimeout_ReturnsDefaultCachePolicyAndTimeout() {
        let request = CachePolicyAndTimeOutRequest()
        XCTAssert(request.cachePolicy == .useProtocolCachePolicy)
        XCTAssert(request.timeout == 30)
    }
        
    func test_NetworkRequest_TransformData() {
        
        let request = CachePolicyAndTimeOutRequest()
        let result: Result<CachePolicyAndTimeOutRequest.ResponseType, CachePolicyAndTimeOutRequest.ErrorType> = request.transformData("this is dummy content".data(using: .utf8)!)
        
        XCTAssertNotNil(result.value)
    }
    
    // MARK: - Private
    
    private func assertParameters<T: NetworkRequest, U>(method: String = NetworkRequestTests.defaultRequestMethod.rawValue,
                                                        urlString: String = NetworkRequestTests.defaultURL.absoluteString,
                                                        headers: [String: String]? = nil,
                                                        body: Data? = nil,
                                                        cachePolicy: URLRequest.CachePolicy = NetworkRequestTests.defaultCachePolicy,
                                                        timeout: TimeInterval = NetworkRequestTests.defaultTimeout,
                                                        for request: T,
                                                        file: StaticString = #file,
                                                        line: UInt = #line) where T.ResponseType == U {
        let urlRequest = request.urlRequest
        
        XCTAssertEqual(urlRequest.httpMethod, method, file: file, line: line)
        XCTAssertEqual(urlRequest.url?.absoluteString, urlString, file: file, line: line)
        XCTAssertEqual(urlRequest.allHTTPHeaderFields ?? [:], headers ?? [:], file: file, line: line)
        XCTAssertEqual(urlRequest.httpBody, body, file: file, line: line)
        XCTAssertEqual(urlRequest.cachePolicy, cachePolicy, file: file, line: line)
        XCTAssertEqual(urlRequest.timeoutInterval, timeout, file: file, line: line)
    }
}

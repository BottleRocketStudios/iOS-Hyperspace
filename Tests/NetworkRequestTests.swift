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
    
    func test_NetworkRequest_ModifyingBody() {
        let body = Data(bytes: [1, 2, 3, 4, 5, 6, 7, 8])
        let request = SimpleGETRequest()
        let modified = request.modifyingBody(body)
        
        XCTAssertEqual(modified.body, body)
        XCTAssertEqual(modified.headers, request.headers)
        XCTAssertEqual(modified.url, request.url)
        XCTAssertEqual(modified.method, request.method)
        XCTAssertEqual(modified.cachePolicy, request.cachePolicy)
        XCTAssertEqual(modified.timeout, request.timeout)
    }
    
    func test_NetworkRequest_ModifyingHeaders() {
        let headers: [HTTP.HeaderKey: HTTP.HeaderValue] = [.authorization: HTTP.HeaderValue(rawValue: "auth")]
        let request = SimpleGETRequest()
        let modified = request.modifyingHeaders([.authorization: HTTP.HeaderValue(rawValue: "auth")])
        
        XCTAssertEqual(modified.body, request.body)
        XCTAssertEqual(modified.headers, headers)
        XCTAssertEqual(modified.url, request.url)
        XCTAssertEqual(modified.method, request.method)
        XCTAssertEqual(modified.cachePolicy, request.cachePolicy)
        XCTAssertEqual(modified.timeout, request.timeout)
    }
    
    func test_NetworkRequest_AddingHeaders() {
        let request = SimpleGETRequest()
        let headers = [HTTP.HeaderKey.authorization: HTTP.HeaderValue(rawValue: "some_value")]
        let new = request.addingHeaders(headers)
        let headers2 = [HTTP.HeaderKey.contentType: HTTP.HeaderValue(rawValue: "some_value")]
        let final = new.addingHeaders(headers2)
        
        let finalHeaders = final.headers
        XCTAssertNotNil(finalHeaders?[.authorization])
        XCTAssertNotNil(finalHeaders?[.contentType])
    }
    
    func test_NetworkRequest_AddingHeadersWhenNonePresent() {
        var request = SimpleGETRequest()
        request.headers = nil
        
        let headers = [HTTP.HeaderKey.authorization: HTTP.HeaderValue(rawValue: "some_value")]
        let final = request.addingHeaders(headers)
        
        let finalHeaders = final.headers
        XCTAssertNotNil(finalHeaders?[.authorization])
    }
    
    func test_NetworkRequest_CollisionsPrefersNewHeadersWhenAddingHeaders() {
        let request = SimpleGETRequest().addingHeaders([.authorization: HTTP.HeaderValue(rawValue: "some_value")])
        let accessToken = "access_token"
        let final = request.addingHeaders([.authorization: HTTP.HeaderValue(rawValue: accessToken)])
        
        let finalHeaders = final.headers
        XCTAssertEqual(finalHeaders?[.authorization]?.rawValue, accessToken)
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

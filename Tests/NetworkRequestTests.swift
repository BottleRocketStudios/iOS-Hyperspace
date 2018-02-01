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
        typealias ResponseType = String
        typealias ErrorType = AnyError
        
        var method: HTTP.Method = NetworkRequestTests.defaultRequestMethod
        var url = NetworkRequestTests.defaultURL
        var queryParameters: [URLQueryItem]?
        var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
        var body: Data?
        var cachePolicy: URLRequest.CachePolicy = NetworkRequestTests.defaultCachePolicy
        var timeout: TimeInterval = NetworkRequestTests.defaultTimeout
    }
    
    struct SimplePOSTRequest: NetworkRequest {
        typealias ResponseType = String
        typealias ErrorType = AnyError
        
        var method: HTTP.Method = .post
        var url = NetworkRequestTests.defaultURL
        var queryParameters: [URLQueryItem]?
        var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
        var body: Data?
        var cachePolicy: URLRequest.CachePolicy = NetworkRequestTests.defaultCachePolicy
        var timeout: TimeInterval = NetworkRequestTests.defaultTimeout
    }
    
    struct CachePolicyAndTimeOutRequest: NetworkRequest {
        typealias ResponseType = EmptyResponse
        typealias ErrorType = AnyError
        
        var method: HTTP.Method = NetworkRequestTests.defaultRequestMethod
        var url = NetworkRequestTests.defaultURL
        var queryParameters: [URLQueryItem]?
        var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
        var body: Data?
    }
    
    struct CustomQueryEncodingRequest: NetworkRequest {
        typealias ResponseType = EmptyResponse
        typealias ErrorType = AnyError
        
        var method: HTTP.Method = NetworkRequestTests.defaultRequestMethod
        var url = NetworkRequestTests.defaultURL
        var queryParameters: [URLQueryItem]?
        var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
        var body: Data?
        var queryParameterEncodingStrategy =  NetworkRequestQueryParameterEncodingStrategy.custom { (content) -> String in
            return content.replacingOccurrences(of: " ", with: "-", options: NSString.CompareOptions.literal, range:nil)
        }
    }
    
    // MARK: - Tests
    
    func test_SimpleGETRequestWithoutQueryParametersOrHeaders_GeneratesCorrectURLRequest() {
        let request = SimpleGETRequest()
        
        assertParameters(for: request)
    }
    
    func test_SimpleGETRequestWithQueryParameters_GeneratesCorrectURLRequest() {
        var request = SimpleGETRequest()
        
        request.queryParameters = [
            URLQueryItem(name: "param1", value: "param1value"),
            URLQueryItem(name: "param2", value: "param2 value"),
            URLQueryItem(name: "param3", value: nil)
            // TODO: What other complex query parameters can we generate to test the URL encoding?
        ]
        
        assertParameters(urlString: "http://apple.com?param1=param1value&param2=param2%20value&param3", for: request)
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
        let _ = EmptyResponse()
        XCTAssert(true)
    }
    
    func test_NetworkRequestWithoutExplicitCachePolicyAndTimeout_ReturnsDefaultCachePolicyAndTimeout() {
        let request = CachePolicyAndTimeOutRequest()
        XCTAssert(request.cachePolicy == .useProtocolCachePolicy)
        XCTAssert(request.timeout == 30)
    }
    
    func test_NetworkRequest_EncodeQueryParameterString() {
        let request = CachePolicyAndTimeOutRequest()
        let queryString = request.encodeQueryParameterString("this is a test")
        
        XCTAssert(queryString == "this%20is%20a%20test")
    }
    
    func test_NetworkRequest_TransformData() {
        
        let request = CachePolicyAndTimeOutRequest()
        let result: Result<CachePolicyAndTimeOutRequest.ResponseType,  CachePolicyAndTimeOutRequest.ErrorType> = request.transformData("this is dummy content".data(using: .utf8)!)
        
        XCTAssertNotNil(result.value)
    }
    
    func test_NetworkRequest_CustomQueryEncoding() {
        let request = CustomQueryEncodingRequest()
        let queryString = request.encodeQueryParameterString("this is a test")
        
        XCTAssert(queryString == "this-is-a-test")
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

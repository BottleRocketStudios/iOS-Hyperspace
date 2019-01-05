//
//  RequestTests.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
import Hyperspace
import Result

// MARK: - Request Implementations
fileprivate extension Request where ResponseType == String, ErrorType == AnyError {
    
    static var simpleGET: Request<String, AnyError> {
        return Request(url: RequestTests.defaultURL, cachePolicy: RequestTests.defaultCachePolicy, timeout: RequestTests.defaultTimeout, transformer: RequestDefaults.successTransformer(for: JSONDecoder()))
    }
    
    static var simplePOST: Request<String, AnyError> {
        return Request(method: .post, url: RequestTests.defaultURL, cachePolicy: RequestTests.defaultCachePolicy, timeout: RequestTests.defaultTimeout, transformer: RequestDefaults.successTransformer(for: JSONDecoder()))
    }
}

fileprivate extension Request where ResponseType == EmptyResponse, ErrorType == AnyError {

    static var cachePolicyAndTimeOut: Request<EmptyResponse, AnyError> {
        return Request(url: RequestTests.defaultURL, transformer: { _ in .success(EmptyResponse()) })
    }
}

class RequestTests: XCTestCase {
    
    // MARK: - Constants
    
    fileprivate static let defaultRequestMethod: HTTP.Method = .get
    fileprivate static let defaultURL = URL(string: "http://apple.com")!
    fileprivate static let defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    fileprivate static let defaultTimeout: TimeInterval = 1.0

    // MARK: - Tests
    
    func test_SimpleGETRequestWithoutQueryParametersOrHeaders_GeneratesCorrectURLRequest() {
        let request: Request<String, AnyError> = .simpleGET
        assertParameters(for: request)
    }
    
    func test_SimpleGETRequestWithHeaders_GeneratesCorrectURLRequest() {
        var request: Request<String, AnyError> = .simpleGET
        request.headers = [.contentType: .applicationJSON]
        
        assertParameters(headers: ["Content-Type": "application/json"], for: request)
    }
    
    func test_SimplePOSTRequestWithData_GeneratesCorrectURLRequest() {
        let bodyData = "Test".data(using: .utf8)!

        var request = Request.simplePOST
        request.body = bodyData

        assertParameters(method: "POST", body: bodyData, for: request)
    }

    func test_Request_EmptyResponseInit() {
        _ = EmptyResponse()
        XCTAssert(true)
    }

    func test_RequestWithoutExplicitCachePolicyAndTimeout_ReturnsDefaultCachePolicyAndTimeout() {
        let request = Request.cachePolicyAndTimeOut
        XCTAssert(request.cachePolicy == .useProtocolCachePolicy)
        XCTAssert(request.timeout == 30)
    }

    func test_Request_TransformData() {

        let request = Request.cachePolicyAndTimeOut
        let data = "this is dummy content".data(using: .utf8)!
        let serviceSuccess = NetworkServiceSuccess(data: data, response: HTTP.Response(code: 200, data: data))
        let result: Result<EmptyResponse, AnyError> = request.transformSuccess(serviceSuccess)

        XCTAssertNotNil(result.value)
    }

    func test_Request_ModifyingBody() {
        let body = Data(bytes: [1, 2, 3, 4, 5, 6, 7, 8])
        let request = Request.simpleGET
        let modified = request.usingBody(body)

        XCTAssertEqual(modified.body, body)
        XCTAssertEqual(modified.headers, request.headers)
        XCTAssertEqual(modified.url, request.url)
        XCTAssertEqual(modified.method, request.method)
        XCTAssertEqual(modified.cachePolicy, request.cachePolicy)
        XCTAssertEqual(modified.timeout, request.timeout)
    }

    func test_Request_ModifyingHeaders() {
        let headers: [HTTP.HeaderKey: HTTP.HeaderValue] = [.authorization: HTTP.HeaderValue(rawValue: "auth")]
        let request = Request.simpleGET
        let modified = request.usingHeaders([.authorization: HTTP.HeaderValue(rawValue: "auth")])

        XCTAssertEqual(modified.body, request.body)
        XCTAssertEqual(modified.headers, headers)
        XCTAssertEqual(modified.url, request.url)
        XCTAssertEqual(modified.method, request.method)
        XCTAssertEqual(modified.cachePolicy, request.cachePolicy)
        XCTAssertEqual(modified.timeout, request.timeout)
    }

    func test_Request_AddingHeaders() {
        let request = Request.simpleGET
        let headers = [HTTP.HeaderKey.authorization: HTTP.HeaderValue(rawValue: "some_value")]
        let new = request.addingHeaders(headers)
        let headers2 = [HTTP.HeaderKey.contentType: HTTP.HeaderValue(rawValue: "some_value")]
        let final = new.addingHeaders(headers2)

        let finalHeaders = final.headers
        XCTAssertNotNil(finalHeaders?[.authorization])
        XCTAssertNotNil(finalHeaders?[.contentType])
    }

    func test_Request_AddingHeadersWhenNonePresent() {
        var request = Request.simpleGET
        request.headers = nil

        let headers = [HTTP.HeaderKey.authorization: HTTP.HeaderValue(rawValue: "some_value")]
        let final = request.addingHeaders(headers)

        let finalHeaders = final.headers
        XCTAssertNotNil(finalHeaders?[.authorization])
    }

    func test_Request_CollisionsPrefersNewHeadersWhenAddingHeaders() {
        let request = Request.simpleGET.addingHeaders([.authorization: HTTP.HeaderValue(rawValue: "some_value")])
        let accessToken = "access_token"
        let final = request.addingHeaders([.authorization: HTTP.HeaderValue(rawValue: accessToken)])

        let finalHeaders = final.headers
        XCTAssertEqual(finalHeaders?[.authorization]?.rawValue, accessToken)
    }

    // MARK: - Private
    
    private func assertParameters<T, U: NetworkServiceFailureInitializable>(method: String = RequestTests.defaultRequestMethod.rawValue,
                                                                            urlString: String = RequestTests.defaultURL.absoluteString,
                                                                            headers: [String: String]? = nil,
                                                                            body: Data? = nil,
                                                                            cachePolicy: URLRequest.CachePolicy = RequestTests.defaultCachePolicy,
                                                                            timeout: TimeInterval = RequestTests.defaultTimeout,
                                                                            for request: Request<T, U>,
                                                                            file: StaticString = #file,
                                                                            line: UInt = #line) {
        let urlRequest = request.urlRequest
        
        XCTAssertEqual(urlRequest.httpMethod, method, file: file, line: line)
        XCTAssertEqual(urlRequest.url?.absoluteString, urlString, file: file, line: line)
        XCTAssertEqual(urlRequest.allHTTPHeaderFields ?? [:], headers ?? [:], file: file, line: line)
        XCTAssertEqual(urlRequest.httpBody, body, file: file, line: line)
        XCTAssertEqual(urlRequest.cachePolicy, cachePolicy, file: file, line: line)
        XCTAssertEqual(urlRequest.timeoutInterval, timeout, file: file, line: line)
    }
}

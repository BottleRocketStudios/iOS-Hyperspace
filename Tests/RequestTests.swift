//
//  RequestTests.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
import Hyperspace

class RequestTests: XCTestCase {
    
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

        var request: Request<String, AnyError> = .simplePOST
        request.body = HTTP.Body(bodyData)
        
        assertParameters(method: "POST", body: bodyData, for: request)
    }

    func test_RequestWithoutExplicitCachePolicyAndTimeout_ReturnsDefaultCachePolicyAndTimeout() {
        let timeout: TimeInterval = 1
        let cachePolicy: URLRequest.CachePolicy = .returnCacheDataDontLoad
        
        RequestDefaults.defaultTimeout = timeout
        RequestDefaults.defaultCachePolicy = cachePolicy
              
        let request: Request<EmptyResponse, AnyError> = .cachePolicyAndTimeoutRequest
        XCTAssertEqual(request.cachePolicy, cachePolicy)
        XCTAssertEqual(request.timeout, timeout)
    }
        
    func test_Request_TransformData() {
        let request: Request<EmptyResponse, AnyError> = .cachePolicyAndTimeoutRequest
        
        let data = "this is dummy content".data(using: .utf8)!
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(urlRequest: request.urlRequest), code: 200, body: data))
        let result: Result<EmptyResponse, AnyError> = request.transform(success: serviceSuccess)
        
        XCTAssertNotNil(result.value)
    }
    
    func test_Request_ModifyingBody() {
        let body = Data([1, 2, 3, 4, 5, 6, 7, 8])
        let request: Request<String, AnyError> = .simpleGET
        let modified = request.usingBody(HTTP.Body(body))
        
        XCTAssertEqual(modified.body?.data, body)
        XCTAssertEqual(modified.headers, request.headers)
        XCTAssertEqual(modified.url, request.url)
        XCTAssertEqual(modified.method, request.method)
        XCTAssertEqual(modified.cachePolicy, request.cachePolicy)
        XCTAssertEqual(modified.timeout, request.timeout)
    }

    func test_Request_AppliesAdditionalHeadersFromBody() throws {
        let request: Request<String, AnyError> = .simpleGET
        let modified = try request.usingBody(.json(MockObject(title: "title", subtitle: "subtitle")))

        let urlRequest = modified.urlRequest
        XCTAssertTrue(urlRequest.allHTTPHeaderFields?.contains { $0.0 == "Content-Type" } == true)
        XCTAssertTrue(urlRequest.allHTTPHeaderFields?.contains { $0.1 == "application/json" } == true)
    }

    func test_Request_HeadersFromBodyDoNotOverrideThoseFromRequest() throws {
        let request: Request<String, AnyError> = .simpleGET
        let modified = try request
            .usingHeaders([.contentType: .multipartForm])
            .usingBody(.json(MockObject(title: "title", subtitle: "subtitle")))

        let urlRequest = modified.urlRequest
        XCTAssertTrue(urlRequest.allHTTPHeaderFields?.contains { $0.0 == "Content-Type" } == true)
        XCTAssertTrue(urlRequest.allHTTPHeaderFields?.contains { $0.1 == "multipart/form-data" } == true)
    }
    
    func test_Request_ModifyingHeaders() {
        let headers: [HTTP.HeaderKey: HTTP.HeaderValue] = [.authorization: HTTP.HeaderValue(rawValue: "auth")]
        let request: Request<String, AnyError> = .simpleGET
        let modified = request.usingHeaders([.authorization: HTTP.HeaderValue(rawValue: "auth")])
        
        XCTAssertEqual(modified.body, request.body)
        XCTAssertEqual(modified.headers, headers)
        XCTAssertEqual(modified.url, request.url)
        XCTAssertEqual(modified.method, request.method)
        XCTAssertEqual(modified.cachePolicy, request.cachePolicy)
        XCTAssertEqual(modified.timeout, request.timeout)
    }
    
    func test_Request_AddingHeaders() {
        let request: Request<String, AnyError> = .simpleGET
        let headers = [HTTP.HeaderKey.authorization: HTTP.HeaderValue(rawValue: "some_value")]
        let new = request.addingHeaders(headers)
        let headers2 = [HTTP.HeaderKey.contentType: HTTP.HeaderValue(rawValue: "some_value")]
        let final = new.addingHeaders(headers2)
        
        let finalHeaders = final.headers
        XCTAssertNotNil(finalHeaders?[.authorization])
        XCTAssertNotNil(finalHeaders?[.contentType])
    }
    
    func test_Request_AddingHeadersWhenNonePresent() {
        var request: Request<String, AnyError> = .simpleGET
        request.headers = nil
        
        let headers = [HTTP.HeaderKey.authorization: HTTP.HeaderValue(rawValue: "some_value")]
        let final = request.addingHeaders(headers)
        
        let finalHeaders = final.headers
        XCTAssertNotNil(finalHeaders?[.authorization])
    }
    
    func test_Request_ModifyingURL() {
        let request: Request<String, AnyError> = .simpleGET
        
        let final = request.usingURL(request.url.appendingQueryItems([URLQueryItem(name: "test", value: "value")]))
        XCTAssertEqual(final.url.absoluteString, "http://apple.com?test=value")
    }
        
    func test_Request_CollisionsPrefersNewHeadersWhenAddingHeaders() {
        let request = Request<String, AnyError>.simpleGET.addingHeaders([.authorization: HTTP.HeaderValue(rawValue: "some_value")])
        let accessToken = "access_token"
        let final = request.addingHeaders([.authorization: HTTP.HeaderValue(rawValue: accessToken)])
        
        let finalHeaders = final.headers
        XCTAssertEqual(finalHeaders?[.authorization]?.rawValue, accessToken)
    }

    func test_Request_CustomURLRequestCreationStrategyUsed() {
        let url = URL(string: "www.apple.com")!
        var request = Request<String, AnyError>.simpleGET
        request.urlRequestCreationStrategy = .custom { _ in URLRequest(url: url) }

        XCTAssertEqual(request.urlRequest.url, url)
    }

    func test_Request_MappingARequestToANewResponseMaintainsErrorType() {
        let exp = expectation(description: "Transformer Executed")
        let response = HTTP.Response(request: HTTP.Request(), code: 200, url: RequestTestDefaults.defaultURL, headers: [:], body: loadedJSONData(fromFileNamed: "Object"))
        let request: Request<MockObject, AnyError> = .init(method: .get, url: RequestTestDefaults.defaultURL)
        let mapped: Request<[MockObject], AnyError> = request.map { exp.fulfill(); return [$0] }

        _ = mapped.transform(success: TransportSuccess(response: response))
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_Request_MappingARequestToANewResponseDoesNotUseHandlerWhenInitialRequestFails() {
        let exp = expectation(description: "Transformer Executed")
        exp.isInverted = true

        let response = HTTP.Response(request: HTTP.Request(), code: 200, url: RequestTestDefaults.defaultURL, headers: [:], body: loadedJSONData(fromFileNamed: "DateObject"))
        let request: Request<MockObject, AnyError> = .init(method: .get, url: RequestTestDefaults.defaultURL)
        let mapped: Request<[MockObject], AnyError> = request.map { exp.fulfill(); return [$0] }

        _ = mapped.transform(success: TransportSuccess(response: response))
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_Request_MappingErrorOfARequestToANewTypeMaintainsResponseType() {
        let exp = expectation(description: "Transformer Executed")
        let response = HTTP.Response(request: HTTP.Request(), code: 200, url: RequestTestDefaults.defaultURL, headers: [:], body: loadedJSONData(fromFileNamed: "DateObject"))
        let request: Request<MockObject, AnyError> = .init(method: .get, url: RequestTestDefaults.defaultURL)
        let mapped: Request<MockObject, MockBackendServiceError> = request.mapError { _ in
            exp.fulfill()
            return MockBackendServiceError(transportFailure: TransportFailure(code: .redirection, request: HTTP.Request(), response: nil))
        }

        _ = mapped.transform(success: TransportSuccess(response: response))
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_Request_MappingErrorOfARequestToANewTypeDoesNotUseHandlerWhenInitialRequestSucceeds() {
        let exp = expectation(description: "Transformer Executed")
        exp.isInverted = true

        let response = HTTP.Response(request: HTTP.Request(), code: 200, url: RequestTestDefaults.defaultURL, headers: [:], body: loadedJSONData(fromFileNamed: "Object"))
        let request: Request<MockObject, AnyError> = .init(method: .get, url: RequestTestDefaults.defaultURL)
        let mapped: Request<MockObject, MockBackendServiceError> = request.mapError { _ in
            exp.fulfill()
            return MockBackendServiceError(transportFailure: TransportFailure(code: .redirection, request: HTTP.Request(), response: nil))
        }

        _ = mapped.transform(success: TransportSuccess(response: response))
        waitForExpectations(timeout: 1, handler: nil)
    }

    // MARK: - Private
    
    private func assertParameters<T, U>(method: String = HTTP.Method.get.rawValue,
                                        urlString: String = "http://apple.com",
                                        headers: [String: String]? = nil,
                                        body: Data? = nil,
                                        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                        timeout: TimeInterval = 1,
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

// MARK: - Request Implementations

private extension Request {

    // MARK: - Request Implementations
    static var simpleGET: Request<String, AnyError> {
        return .init(method: .get, url: URL(string: "http://apple.com")!, cachePolicy: .useProtocolCachePolicy, timeout: 1)
    }
    
    static var simplePOST: Request<String, AnyError> {
        return .init(method: .post, url: URL(string: "http://apple.com")!, cachePolicy: .useProtocolCachePolicy, timeout: 1)
    }
    
    static var cachePolicyAndTimeoutRequest: Request<EmptyResponse, AnyError> {
        return .withEmptyResponse(method: .get, url: URL(string: "http://apple.com")!)
    }
}

//
//  RequestTests.swift
//  Tests
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
import Hyperspace

class RequestTests: XCTestCase {

    // MARK: - Tests

    func test_SimpleGETRequestWithoutQueryParametersOrHeaders_GeneratesCorrectURLRequest() {
        let request: Request<String> = .simpleGET
        assertParameters(for: request)
    }

    func test_SimpleGETRequestWithHeaders_GeneratesCorrectURLRequest() {
        var request: Request<String> = .simpleGET
        request.headers = [.contentType: .applicationJSON]

        assertParameters(headers: ["Content-Type": "application/json"], for: request)
    }

    func test_SimplePOSTRequestWithData_GeneratesCorrectURLRequest() {
        let bodyData = "Test".data(using: .utf8)!

        var request: Request<String> = .simplePOST
        request.body = HTTP.Body(bodyData)

        assertParameters(method: "POST", body: bodyData, for: request)
    }

    func test_RequestWithoutExplicitCachePolicyAndTimeout_ReturnsDefaultCachePolicyAndTimeout() {
        let timeout: TimeInterval = 1
        let cachePolicy: URLRequest.CachePolicy = .returnCacheDataDontLoad

        RequestDefaults.defaultTimeout = timeout
        RequestDefaults.defaultCachePolicy = cachePolicy

        let request: Request<Void> = .cachePolicyAndTimeoutRequest
        XCTAssertEqual(request.cachePolicy, cachePolicy)
        XCTAssertEqual(request.timeout, timeout)
    }

    func test_Request_TransformData() async {
        let request: Request<Void> = .cachePolicyAndTimeoutRequest

        let data = "this is dummy content".data(using: .utf8)!
        let serviceSuccess = TransportSuccess(response: HTTP.Response(request: HTTP.Request(urlRequest: request.urlRequest), code: 200, body: data))
        let result: Void? = try? await request.transform(success: serviceSuccess)

        XCTAssertNotNil(result)
    }

    func test_Request_ModifyingBody() {
        let body = Data([1, 2, 3, 4, 5, 6, 7, 8])
        let request: Request<String> = .simpleGET
        let modified = request.usingBody(HTTP.Body(body))

        XCTAssertEqual(modified.body?.data, body)
        XCTAssertEqual(modified.headers, request.headers)
        XCTAssertEqual(modified.url, request.url)
        XCTAssertEqual(modified.method, request.method)
        XCTAssertEqual(modified.cachePolicy, request.cachePolicy)
        XCTAssertEqual(modified.timeout, request.timeout)
    }

    func test_Request_AppliesAdditionalHeadersFromBody() throws {
        let request: Request<String> = .simpleGET
        let modified = try request.usingBody(.json(MockObject(title: "title", subtitle: "subtitle")))

        let urlRequest = modified.urlRequest
        XCTAssertTrue(urlRequest.allHTTPHeaderFields?.contains { $0.0 == "Content-Type" } == true)
        XCTAssertTrue(urlRequest.allHTTPHeaderFields?.contains { $0.1 == "application/json" } == true)
    }

    func test_Request_HeadersFromBodyDoNotOverrideThoseFromRequest() throws {
        let request: Request<String> = .simpleGET
        let modified = try request
            .usingHeaders([.contentType: .multipartForm])
            .usingBody(.json(MockObject(title: "title", subtitle: "subtitle")))

        let urlRequest = modified.urlRequest
        XCTAssertTrue(urlRequest.allHTTPHeaderFields?.contains { $0.0 == "Content-Type" } == true)
        XCTAssertTrue(urlRequest.allHTTPHeaderFields?.contains { $0.1 == "multipart/form-data" } == true)
    }

    func test_Request_ModifyingHeaders() {
        let headers: [HTTP.HeaderKey: HTTP.HeaderValue] = [.authorization: HTTP.HeaderValue(rawValue: "auth")]
        let request: Request<String> = .simpleGET
        let modified = request.usingHeaders([.authorization: HTTP.HeaderValue(rawValue: "auth")])

        XCTAssertEqual(modified.body, request.body)
        XCTAssertEqual(modified.headers, headers)
        XCTAssertEqual(modified.url, request.url)
        XCTAssertEqual(modified.method, request.method)
        XCTAssertEqual(modified.cachePolicy, request.cachePolicy)
        XCTAssertEqual(modified.timeout, request.timeout)
    }

    func test_Request_AddingHeaders() {
        let request: Request<String> = .simpleGET
        let headers = [HTTP.HeaderKey.authorization: HTTP.HeaderValue(rawValue: "some_value")]
        let new = request.addingHeaders(headers)
        let headers2 = [HTTP.HeaderKey.contentType: HTTP.HeaderValue(rawValue: "some_value")]
        let final = new.addingHeaders(headers2)

        let finalHeaders = final.headers
        XCTAssertNotNil(finalHeaders?[.authorization])
        XCTAssertNotNil(finalHeaders?[.contentType])
    }

    func test_Request_AddingHeadersWhenNonePresent() {
        var request: Request<String> = .simpleGET
        request.headers = nil

        let headers = [HTTP.HeaderKey.authorization: HTTP.HeaderValue(rawValue: "some_value")]
        let final = request.addingHeaders(headers)

        let finalHeaders = final.headers
        XCTAssertNotNil(finalHeaders?[.authorization])
    }

    func test_Request_CollisionsPrefersNewHeadersWhenAddingHeaders() {
        let request = Request<String>.simpleGET.addingHeaders([.authorization: HTTP.HeaderValue(rawValue: "some_value")])
        let accessToken = "access_token"
        let final = request.addingHeaders([.authorization: HTTP.HeaderValue(rawValue: accessToken)])

        let finalHeaders = final.headers
        XCTAssertEqual(finalHeaders?[.authorization]?.rawValue, accessToken)
    }

    func test_Request_CustomURLRequestCreationStrategyUsed() {
        let url = URL(string: "www.apple.com")!
        var request = Request<String>.simpleGET
        request.urlRequestCreationStrategy = .custom { _ in URLRequest(url: url) }

        XCTAssertEqual(request.urlRequest.url, url)
    }

    func test_Request_MappingARequestToANewResponseMaintainsErrorType() async {
        let response = HTTP.Response(request: HTTP.Request(), code: 200, url: RequestTestDefaults.defaultURL, headers: [:], body: loadedJSONData(fromFileNamed: "Object"))
        let request: Request<MockObject> = .init(method: .get, url: RequestTestDefaults.defaultURL)
        let mapped: Request<[MockObject]> = request.map { [$0] }

        _ = try! await mapped.transform(success: TransportSuccess(response: response))
    }

    func test_Request_MappingARequestToANewResponsePassesTransportSuccessFromResponse() async {
        let response = HTTP.Response(request: HTTP.Request(), code: 200, url: RequestTestDefaults.defaultURL, headers: [:], body: loadedJSONData(fromFileNamed: "Object"))
        let success = TransportSuccess(response: response)

        let request: Request<MockObject> = .init(method: .get, url: RequestTestDefaults.defaultURL)
        let mapped: Request<(TransportSuccess, [MockObject])> = request.map {
            XCTAssertEqual($0, success)
            return ($0, [$1])
        }

        _ = try! await mapped.transform(success: success)
    }

    func test_Request_MappingARequestToANewResponseDoesNotUseHandlerWhenInitialRequestFails() async {
        let response = HTTP.Response(request: HTTP.Request(), code: 200, url: RequestTestDefaults.defaultURL, headers: [:], body: loadedJSONData(fromFileNamed: "DateObject"))
        let request: Request<MockDate> = .init(method: .get, url: RequestTestDefaults.defaultURL, decoder: .iso8601)
        let mapped: Request<[MockDate]> = request.map { [$0] }

        _ = try! await mapped.transform(success: TransportSuccess(response: response))
    }

    // MARK: - Private

    private func assertParameters<R>(method: String = HTTP.Method.get.rawValue,
                                     urlString: String = "http://apple.com",
                                     headers: [String: String]? = nil,
                                     body: Data? = nil,
                                     cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                     timeout: TimeInterval = 1,
                                     for request: Request<R>,
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

// MARK: - Request + Convenience
private extension Request {

    static var simpleGET: Request<String> {
        return .init(method: .get, url: URL(string: "http://apple.com")!, cachePolicy: .useProtocolCachePolicy, timeout: 1)
    }

    static var simplePOST: Request<String> {
        return .init(method: .post, url: URL(string: "http://apple.com")!, cachePolicy: .useProtocolCachePolicy, timeout: 1)
    }

    static var cachePolicyAndTimeoutRequest: Request<Void> {
        return .withEmptyResponse(method: .get, url: URL(string: "http://apple.com")!)
    }
}

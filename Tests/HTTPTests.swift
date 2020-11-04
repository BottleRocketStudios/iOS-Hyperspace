//
//  HTTPTest.swift
//  HyperspaceTests
//
//  Created by Adam Brzozowski on 1/30/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class HTTPTests: XCTestCase {
    
    // MARK: - Tests
    
    func test_AuthorizationBearerHeaderValue_IsGeneratedCorrectly() {
        let authorizationBearer = HTTP.HeaderValue.authorizationBearer(token: "1234567890")
        XCTAssertEqual(authorizationBearer.rawValue, "Bearer 1234567890")
    }
    
    func test_HeaderKey_RawValuesAreCorrect() {
        let headerKeys: [HTTP.HeaderKey: String] = [
            .accept: "Accept",
            .acceptCharset: "Accept-Charset",
            .acceptEncoding: "Accept-Encoding",
            .acceptLanguage: "Accept-Language",
            .acceptDatetime: "Accept-Datetime",
            .authorization: "Authorization",
            .contentLength: "Content-Length",
            .contentMD5: "Content-MD5",
            .contentType: "Content-Type",
            .date: "Date",
            .userAgent: "User-Agent"
        ]
        
        headerKeys.forEach { (key, value) in
            XCTAssertEqual(key, HTTP.HeaderKey(rawValue: value))
            XCTAssertEqual(key, HTTP.HeaderKey(stringLiteral: value))
        }
    }
    
    func test_HeaderValue_RawValuesAreCorrect() {
        let headerValues: [String: HTTP.HeaderValue] = [
            "application/json": .applicationJSON,
            "application/x-www-form-urlencoded": .applicationFormURLEncoded,
            "application/xml": .applicationXML,
            "multipart/form-data": .multipartForm,
            "text/plain": .textPlain,
            "image/png": .imagePNG,
            "image/jpeg": .imageJPEG,
            "image/gif": .imageGIF,
            "compress": .encodingCompress,
            "deflate": .encodingDeflate,
            "exi": .encodingExi,
            "gzip": .encodingGzip,
            "identity": .encodingIdentity,
            "pack200-gzip": .encodingPack200Gzip,
            "br": .encodingBr,
            "application/vnd.apple.pkpass": .passKit
        ]

        headerValues.forEach { (key, value) in
            XCTAssertEqual(value, HTTP.HeaderValue(rawValue: key))
            XCTAssertEqual(value, HTTP.HeaderValue(stringLiteral: key))
        }
    }
    
    func test_ResponseDataString_ReturnsResponseDataAsString() {
        let content = "This is my data"
        let response = HTTP.Response(request: HTTP.Request(), code: 200, body: content.data(using: .utf8))
        let dataString = response.bodyString
        
        XCTAssertEqual(dataString, content)
    }

    func test_Response_ReturnsAppropriateMessageForStatus() {
        let response = HTTP.Response(request: HTTP.Request(), code: 400)
        XCTAssertEqual(response.statusMessage, "bad request")
    }
    
    func test_HTTPResponseInitWithCode200_ProducesStatusSuccessOK() {
        let response = HTTP.Response(request: HTTP.Request(), code: 200, body: nil)
        switch response.status {
        case .success(let status):
            XCTAssertEqual(status, HTTP.Status.Success.ok)
        default:
            XCTFail("200 status should produce a 'success - ok' response")
        }
    }
    
    func test_HTTPStatusInitWithCode300_ProducesStatusRedirectionMultipleChoices() {
        let response = HTTP.Response(request: HTTP.Request(), code: 300, body: nil)
        switch response.status {
        case .redirection(let status):
            XCTAssertEqual(status, HTTP.Status.Redirection.multipleChoices)
        default:
            XCTFail("300 status should produce a 'redirection - multiple choices' response")
        }
    }
    
    func test_HTTPStatusInitWithCode400_ProducesStatusClientErrorBadRequest() {
        let response = HTTP.Response(request: HTTP.Request(), code: 400, body: nil)
        switch response.status {
        case .clientError(let status):
            XCTAssertEqual(status, HTTP.Status.ClientError.badRequest)
        default:
            XCTFail("400 status should produce a 'client error - bad request' response")
        }
    }
    
    func test_HTTPStatusInitWithCode500_ProducesStatusServerErrorInternalServerError() {
        let response = HTTP.Response(request: HTTP.Request(), code: 500, body: nil)
        switch response.status {
        case .serverError(let status):
            XCTAssertEqual(status, HTTP.Status.ServerError.internalServerError)
        default:
            XCTFail("500 status should produce a 'server error - internal server error' response")
        }
    }
    
    func test_HTTPStatusInitWithCode100_ProducesStatusUnknown() {
        let response = HTTP.Response(request: HTTP.Request(), code: 100, body: nil)
        switch response.status {
        case .unknown(let code):
            XCTAssertEqual(code, 100)
        default:
            XCTFail("100 status should produce an 'unknown' response")
        }
    }

    func test_HTTPBodyWithEncodable_ProducesProperlyEncodedData() {
        let encodable = MockObject(title: "title", subtitle: "subtitle")
        let encoder = JSONEncoder()

        do {
            let body = try HTTP.Body.json(encodable, encoder: encoder)
            let data = try encoder.encode(encodable)
            XCTAssertEqual(body.data, data)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_HTTPBodyWithEncodableAndContainer_ProducesProperlyEncodedData() {
        let encodable = MockObject(title: "title", subtitle: "subtitle")
        let encoder = JSONEncoder()

        do {
            let body = try HTTP.Body.json(encodable, container: MockCodableContainer.self, encoder: encoder)
            let data = try encoder.encode(encodable, in: MockCodableContainer.self)
            XCTAssertEqual(body.data, data)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_HTTPBodyWithFormContent_ProducesProperlyEncodedData() {
        let content = [("hello world", "hello world")]
        let encoder = FormURLEncoder()

        let body = HTTP.Body.urlForm(using: content)
        let data = encoder.encode(content)
        XCTAssertEqual(body.data, data)
    }
}

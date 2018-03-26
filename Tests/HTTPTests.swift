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
    
    func test_HTTP_GetAuthorizationBearer() {
        let authorizationBearer = HTTP.HeaderValue.authorizationBearer(token: "1234567890")
        
        XCTAssert(authorizationBearer.rawValue == "Bearer 1234567890")
    }
    
    func test_HTTP_CompareHeaderKey() {
        
        let items = [
            HTTP.HeaderKey.accept: "Accept",
            HTTP.HeaderKey.acceptCharset: "Accept-Charset",
            HTTP.HeaderKey.acceptEncoding: "Accept-Encoding",
            HTTP.HeaderKey.acceptLanguage: "Accept-Language",
            HTTP.HeaderKey.acceptDatetime: "Accept-Datetime",
            HTTP.HeaderKey.authorization: "Authorization",
            HTTP.HeaderKey.contentLength: "Content-Length",
            HTTP.HeaderKey.contentMD5: "Content-MD5",
            HTTP.HeaderKey.contentType: "Content-Type",
            HTTP.HeaderKey.date: "Date",
            HTTP.HeaderKey.userAgent: "User-Agent"
        ]
        
        items.forEach { (key, value) in
            XCTAssert(key == HTTP.HeaderKey(rawValue: value), "\(key) == \(HTTP.HeaderKey(rawValue: value))")
        }
    }
    
    func test_HTTP_EqualityHeaderValue() {
        let items: [String: HTTP.HeaderValue] = [
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

        items.forEach { (key, value) in
            XCTAssert(HTTP.HeaderValue(rawValue: key) == value)
        }
    }

    func test_HTTPResponse_GetDataString() {
        let content = "This is my data"
        let response = HTTP.Response(code: 200, data: content.data(using: .utf8))
        let dataString = response.dataString
        
        XCTAssert(dataString == content)
    }
    
    func test_HTTPResponseInitWithCode200_ProducesStatusSuccessOK() {
        let response = HTTP.Response(code: 200, data: nil)
        switch response.status {
        case .success(let status):
            XCTAssert(status == HTTP.Status.Success.ok)
        default:
            XCTFail("HTTP Response indicates failure")
        }
    }
    
    func test_HTTPStatusInitWithCode299_ProducesStatusSuccessUnknown() {
        let response = HTTP.Response(code: 299, data: nil)
        switch response.status {
        case .success(let status):
            XCTAssert(status == HTTP.Status.Success.unknown)
        default:
            XCTFail("HTTP Response indicates failure")
        }
    }
    
    func test_HTTPStatusInitWithCode300_ProducesStatusRedirectionMultipleChoices() {
        let response = HTTP.Response(code: 300, data: nil)
        switch response.status {
        case .redirection(let status):
            XCTAssert(status == HTTP.Status.Redirection.multipleChoices)
        default:
            XCTFail("HTTP Response indicates failure")
        }
    }
    
    func test_HTTPStatusInitWithCode399_ProducesStatusRedirectionUnknown() {
        let response = HTTP.Response(code: 399, data: nil)
        switch response.status {
        case .redirection(let status):
            XCTAssert(status == HTTP.Status.Redirection.unknown)
        default:
            XCTFail("HTTP Response indicates failure")
        }
    }
    
    func test_HTTPStatusInitWithCode400_ProducesStatusClientErrorBadRequest() {
        let response = HTTP.Response(code: 400, data: nil)
        switch response.status {
        case .clientError(let status):
            XCTAssert(status == HTTP.Status.ClientError.badRequest)
        default:
            XCTFail("HTTP Response indicates failure")
        }
    }
    
    func test_HTTPStatusInitWithCode499_ProducesStatusClientErrorUnknown() {
        let response = HTTP.Response(code: 499, data: nil)
        switch response.status {
        case .clientError(let status):
            XCTAssert(status == HTTP.Status.ClientError.unknown)
        default:
            XCTFail("HTTP Response indicates failure")
        }
    }
    
    func test_HTTPStatusInitWithCode500_ProducesStatusServerErrorInternalServerError() {
        let response = HTTP.Response(code: 500, data: nil)
        switch response.status {
        case .serverError(let status):
            XCTAssert(status == HTTP.Status.ServerError.internalServerError)
        default:
            XCTFail("HTTP Response indicates failure")
        }
    }
    
    func test_HTTPStatusInitWithCode599_ProducesStatusServerErrorUnknown() {
        let response = HTTP.Response(code: 599, data: nil)
        switch response.status {
        case .serverError(let status):
            XCTAssert(status == HTTP.Status.ServerError.unknown)
        default:
            XCTFail("HTTP Response indicates failure")
        }
    }
    
    func test_HTTPStatusInitWithCode100_ProducesStatusUnknown() {
        let response = HTTP.Response(code: 100, data: nil)
        switch response.status {
        case .unknown(let code):
            XCTAssert(code == 100)
        default:
            XCTFail("HTTP Response indicates failure")
        }
    }
}

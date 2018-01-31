//
//  HTTPTest.swift
//  HyperspaceTests
//
//  Created by Adam Brzozowski on 1/30/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import XCTest
import Hyperspace

class HTTPTest: XCTestCase {
    
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
        
        items.forEach { (arg) in
            
            let (key, value) = arg
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

        
        items.forEach { (arg) in

            let (key, value) = arg
            XCTAssert(HTTP.HeaderValue(rawValue: key) == value)
        }
    }

    func test_HTTPResponse_GetDataString() {
        let content = "This is my data"
        let response = HTTP.Response(code: 200, data: content.data(using: .utf8))
        let dataString = response.dataString
        
        XCTAssert(dataString == content)
    }
    
    func test_HTTPStatus_InitWithCode200() {
        let response = HTTP.Response(code: 200, data: nil)
        switch response.status {
        case .success(let status):
            XCTAssert(status.rawValue == 200)
        default:
            XCTFail()
        }
    }
    
    func test_HTTPStatus_InitWithCode299() {
        let response = HTTP.Response(code: 299, data: nil)
        switch response.status {
        case .success(let status):
            XCTAssert(status.rawValue == -1)
        default:
            XCTFail()
        }
    }
    
    func test_HTTPStatus_InitWithCode300() {
        let response = HTTP.Response(code: 300, data: nil)
        switch response.status {
        case .redirection(let status):
            XCTAssert(status.rawValue == 300)
        default:
            XCTFail()
        }
    }
    
    func test_HTTPStatus_InitWithCode399() {
        let response = HTTP.Response(code: 399, data: nil)
        switch response.status {
        case .redirection(let status):
            XCTAssert(status.rawValue == -1)
        default:
            XCTFail()
        }
    }
    
    func test_HTTPStatus_InitWithCode400() {
        let response = HTTP.Response(code: 400, data: nil)
        switch response.status {
        case .clientError(let status):
            XCTAssert(status.rawValue == 400)
        default:
            XCTFail()
        }
    }
    
    func test_HTTPStatus_InitWithCode499() {
        let response = HTTP.Response(code: 499, data: nil)
        switch response.status {
        case .clientError(let status):
            XCTAssert(status.rawValue == -1)
        default:
            XCTFail()
        }
    }
    
    func test_HTTPStatus_InitWithCode500() {
        let response = HTTP.Response(code: 500, data: nil)
        switch response.status {
        case .serverError(let status):
            XCTAssert(status.rawValue == 500)
        default:
            XCTFail()
        }
    }
    
    func test_HTTPStatus_InitWithCode599() {
        let response = HTTP.Response(code: 599, data: nil)
        switch response.status {
        case .serverError(let status):
            XCTAssert(status.rawValue == -1)
        default:
            XCTFail()
        }
    }
    
    func test_HTTPStatus_InitWithCode100() {
        let response = HTTP.Response(code: 100, data: nil)
        switch response.status {
        case .unknown(let code):
            XCTAssert(code == 100)
        default:
            XCTFail()
        }
    }
}

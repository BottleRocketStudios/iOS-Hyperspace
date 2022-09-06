//
//  URLFormEncoderTests.swift
//  Tests
//
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class URLFormEncoderTests: XCTestCase {

    // MARK: - Properties
    private let encoder = URLFormEncoder()

    // MARK: - Tests
    func test_urlFormEncoder_encodesFollowingHTMLSpec() {
        guard let encoded = encoder.encode([("hello world", "/?&+ ")]) else {
            return XCTFail("Could not properly URL Form encode the value")
        }

        let string = String(data: encoded, encoding: .utf8)
        let decoded = string?.removingPercentEncoding
        XCTAssertEqual(decoded, "hello+world=/?&++")
    }

    func test_urlFormEncoder_encodesSpacesAsPlus() {
        let encoded = encoder.formURLEscaped(string: "hello world")
        XCTAssertEqual(encoded, "hello+world")
    }

    func test_urlFormEncoder_encodesAmpersand() {
        let encoded = encoder.formURLEscaped(string: "hello&world")
        XCTAssertEqual(encoded, "hello%26world")
    }

    func test_urlFormEncoder_percentEncodesPlus() {
        let encoded = encoder.formURLEscaped(string: "hello+world")
        XCTAssertEqual(encoded, "hello%2Bworld")
    }

    func test_urlFormEncoder_percentEncodesSlashAndQuestionMark() {
        let encoded = encoder.formURLEscaped(string: "hello/?")
        XCTAssertEqual(encoded, "hello%2F%3F")
    }

    func test_urlFormEncoder_allowedCharacterSetAppropriateCharacters() {
        XCTAssertFalse(CharacterSet.urlFormAllowed.isSuperset(of: .urlQueryAllowed))
        XCTAssertTrue(CharacterSet.urlFormAllowed.contains(" "))
        XCTAssertFalse(CharacterSet.urlFormAllowed.contains("/"))
        XCTAssertFalse(CharacterSet.urlFormAllowed.contains("?"))
        XCTAssertFalse(CharacterSet.urlFormAllowed.contains("+"))
        XCTAssertFalse(CharacterSet.urlFormAllowed.contains("&"))
    }
}

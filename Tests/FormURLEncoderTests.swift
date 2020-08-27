//
//  FormURLEncoderTests.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 8/18/20.
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class FormURLEncoderTests: XCTestCase {

    private let encoder = FormURLEncoder()

    func test_formURLEncoder_encodesFollowingHTMLSpec() {
        guard let encoded = encoder.encode([("hello world", "/?+ ")]) else {
            return XCTFail("Could not properly URL Form encode the value")
        }

        let string = String(data: encoded, encoding: .utf8)
        let decoded = string?.removingPercentEncoding
        XCTAssertEqual(decoded, "hello+world=/?++")
    }

    func test_formURLEncoder_encodesSpacesAsPlus() {
        let encoded = encoder.formURLEscaped(string: "hello world")
        XCTAssertEqual(encoded, "hello+world")
    }

    func test_formURLEncoder_percentEncodesPlus() {
        let encoded = encoder.formURLEscaped(string: "hello+world")
        XCTAssertEqual(encoded, "hello%2Bworld")
    }

    func test_formURLEncoder_percentEncodesSlashAndQuestionMark() {
        let encoded = encoder.formURLEscaped(string: "hello/?")
        XCTAssertEqual(encoded, "hello%2F%3F")
    }

    func test_formURLEncoder_allowedCharacterSetAppropriateCharacters() {
        XCTAssertFalse(CharacterSet.urlFormAllowed.isSuperset(of: .urlQueryAllowed))
        XCTAssertTrue(CharacterSet.urlFormAllowed.contains(" "))
        XCTAssertFalse(CharacterSet.urlFormAllowed.contains("/"))
        XCTAssertFalse(CharacterSet.urlFormAllowed.contains("?"))
        XCTAssertFalse(CharacterSet.urlFormAllowed.contains("+"))
    }
}

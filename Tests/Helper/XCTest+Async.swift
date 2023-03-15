//
//  XCTest+Async.swift
//  Hyperspace
//
//  Created by Will McGinty on 5/26/22.
//  Copyright © 2022 Bottle Rocket Studios. All rights reserved.
//

import XCTest

extension XCTest {

    func XCTAssertThrowsError<T: Sendable>(_ expression: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "",
                                           file: StaticString = #filePath, line: UInt = #line,
                                           errorHandler: (_ error: Error) -> Void = { _ in }) async {
        do {
            _ = try await expression()
            XCTFail(message(), file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }

    func XCTAssertNoThrow<T: Sendable>(_ expression: @autoclosure () async throws -> T,
                                       file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await expression()
        } catch {
            XCTFail(error.localizedDescription, file: file, line: line)
        }
    }
}

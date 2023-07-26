//
//  PreparationStrategyTests.swift
//  Hyperspace
//
//  Created by Will McGinty on 7/26/23.
//  Copyright © 2023 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class PreparationStrategyTests: XCTestCase {

    private struct SendDatePreparationStrategy: PreparationStrategy {

        // MARK: - Properties
        let date: Date
        let dateFormatter = ISO8601DateFormatter()

        // MARK: - Interface
        func prepare<R>(toExecute request: Request<R>) async throws -> Request<R> {
            return request.addingHeaders([.acceptDatetime: .init(rawValue: dateFormatter.string(from: date))])
        }
    }

    func testPreparationStrategy_correctlyModifiesIncomingRequest() async throws {
        let request: Request<String> = .simpleGET
        let date = Date()
        let preparationStrategy = SendDatePreparationStrategy(date: date)

        let preparedRequest = try await preparationStrategy.prepare(toExecute: request)
        XCTAssertEqual(preparedRequest.url, request.url)
        XCTAssertNil(request.headers)
        XCTAssertEqual(preparedRequest.headers?.contains(where: { $0.key == .acceptDatetime }), true)
        XCTAssertEqual(preparedRequest.headers?.first(where: { $0.key == .acceptDatetime })?.value.rawValue,
                       preparationStrategy.dateFormatter.string(from: date))
    }
}

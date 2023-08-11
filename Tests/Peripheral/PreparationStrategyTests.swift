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

    // MARK: - Subtypes
    private struct SendDatePreparationStrategy: PreparationStrategy {

        // MARK: - Properties
        let date: Date
        let dateFormatter = ISO8601DateFormatter()

        // MARK: - Interface
        func prepare<R>(toExecute request: Request<R>) async throws -> Request<R> {
            return request.addingHeaders([.acceptDatetime: .init(rawValue: dateFormatter.string(from: date))])
        }
    }

    private struct ThrowingPreparationStrategy: PreparationStrategy {

        enum Error: Swift.Error {
            case invalidPreparation
        }

        func prepare<R>(toExecute request: Request<R>) async throws -> Request<R> {
            throw Error.invalidPreparation
        }
    }

    // MARK: - Typealias

    typealias DefaultModel = RequestTestDefaults.DefaultModel

    // MARK: - Properties

    private let modelJSONData = RequestTestDefaults.defaultModelJSONData
    private let defaultRequest: Request<DefaultModel> = RequestTestDefaults.defaultRequest()
    private lazy var defaultHTTPRequest = HTTP.Request(urlRequest: defaultRequest.urlRequest)
    private lazy var defaultSuccessResponse = HTTP.Response(request: defaultHTTPRequest, code: 200, body: modelJSONData)
    private lazy var defaultFailureResponse = HTTP.Response(request: defaultHTTPRequest, code: 500)

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

    func testBackendService_errorsThrownFromPreparationStrategyAreImmediatelyThrownToCaller() async {
        let transportService = MockTransportService(responseResult: .failure(.init(kind: .unknown, response: defaultFailureResponse)))
        let backendService = BackendService(transportService: transportService, preparationStrategies: ThrowingPreparationStrategy())

        do {
            _ = try await backendService.execute(request: .simpleGET)
            XCTFail("Preparation for execution should fail.")
        } catch {
            XCTAssertEqual(transportService.executeCallCount, 0)
            XCTAssertNil(transportService.lastExecutedURLRequest)
            XCTAssert(error is ThrowingPreparationStrategy.Error)
        }
    }

    func testBackendService_preparationStrategiesAreExecutedInOrder() async throws {
        let transportService = MockTransportService(responseResult: .success(.init(response: defaultSuccessResponse)))
        let truePrepStrategy = SendDatePreparationStrategy(date: Date())
        let backendService = BackendService(transportService: transportService, preparationStrategies: SendDatePreparationStrategy(date: .distantPast), truePrepStrategy)

        let request = defaultRequest.map { transportSuccess, model in
            XCTAssertEqual(transportSuccess.request.headers?.contains(where: { $0.key == .acceptDatetime }), true)
            XCTAssertEqual(transportSuccess.request.headers?.first(where: { $0.key == .acceptDatetime })?.value.rawValue,
                           truePrepStrategy.dateFormatter.string(from: truePrepStrategy.date))
            return model
        }

        _ = try await backendService.execute(request: request)
    }
}

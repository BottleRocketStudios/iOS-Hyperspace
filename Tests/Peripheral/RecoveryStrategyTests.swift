//
//  RecoveryStrategyTests.swift
//  Tests
//
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class RecoveryStrategyTests: XCTestCase {

    // MARK: - MockRecoverable Subtype
    struct MockRecoverable: Recoverable {
        var recoveryAttemptCount: UInt = 0
        var maxRecoveryAttempts: UInt? = 1
    }

    // MARK: - MockAuthorizationRecoveryStrategy Subtype
    struct MockAuthorizationRecoveryStrategy: RecoveryStrategy {

        func attemptRecovery<R>(from error: Error, executing request: Request<R>) async -> RecoveryDisposition<Request<R>> {
            guard let transportFailure = error as? TransportFailure, case let .clientError(clientError) = transportFailure.kind, clientError == .unauthorized else { return .notAttempted }
            guard let nextAttempt = request.updatedForNextAttempt() else { return .failure(error) }

            let authorized = nextAttempt.addingHeaders([.authorization: HTTP.HeaderValue(rawValue: "some_access_token")])
            return .retry(authorized)
        }
    }

    // MARK: - MockFailureRecoveryStrategy Subtype
    struct MockFailureRecoveryStrategy: RecoveryStrategy {

        func attemptRecovery<R>(from error: Error, executing request: Request<R>) async -> RecoveryDisposition<Request<R>> {
            return .failure(error)
        }
    }

    // MARK: - MockRecoverableTransportService Subtype
    class MockRecoverableTransportService: Transporting {
        var responseCreator: (URLRequest) -> TransportResult

        init(responseCreator: @escaping (URLRequest) -> TransportResult) {
            self.responseCreator = responseCreator
        }

        func execute(request: URLRequest) async throws -> TransportSuccess {
            return try await execute(request: request, delegate: nil)
        }

        func execute(request: URLRequest, delegate: TransportTaskDelegate?) async throws -> TransportSuccess {
            return try responseCreator(request).get()
        }

        // MARK: Presets
        static func protectedService<T: Encodable>(for object: T) -> MockRecoverableTransportService {
            return MockRecoverableTransportService { request -> TransportResult in

                let httpRequest = HTTP.Request()
                if request.allHTTPHeaderFields?["Authorization"] != nil {
                    let data = (try? JSONEncoder().encode(object)) ?? Data()
                    return .success(.init(response: HTTP.Response(request: httpRequest, code: 200, body: data)))
                } else {
                    return .failure(.init(kind: .clientError(.unauthorized), request: httpRequest, response: .init(request: httpRequest, code: 401)))
                }
            }
        }
    }

    // MARK: - Properties
    private var backendService: BackendService?

    // MARK: - Tests
    func test_Recoverable_isProperlyRecoverable() {
        let mockOne = MockRecoverable(recoveryAttemptCount: 0, maxRecoveryAttempts: 3)
        XCTAssertTrue(mockOne.isRecoverable)

        let mockTwo = MockRecoverable(recoveryAttemptCount: 3, maxRecoveryAttempts: 3)
        XCTAssertFalse(mockTwo.isRecoverable)

        let mockThree = MockRecoverable(recoveryAttemptCount: 5, maxRecoveryAttempts: 3)
        XCTAssertFalse(mockThree.isRecoverable)

        let mockFour = MockRecoverable(recoveryAttemptCount: 0, maxRecoveryAttempts: 0)
        XCTAssertFalse(mockFour.isRecoverable)

        let mockFive = MockRecoverable(recoveryAttemptCount: 0, maxRecoveryAttempts: nil)
        XCTAssertTrue(mockFive.isRecoverable)
    }

    func test_Recoverable_CreationOfNextAttemptSucceedsWhenAttemptsRemain() {
        let recoverable = MockRecoverable(recoveryAttemptCount: 0, maxRecoveryAttempts: 1)
        let nextAttempt = recoverable.updatedForNextAttempt()
        XCTAssertNotNil(nextAttempt)
        XCTAssertEqual(recoverable.recoveryAttemptCount + 1, nextAttempt?.recoveryAttemptCount)
    }

    func test_Recoverable_CreationOfNextAttemptFailsAtMaxAttemptCount() {
        let recoverableTwo = MockRecoverable(recoveryAttemptCount: 1, maxRecoveryAttempts: 1)
        XCTAssertNil(recoverableTwo.updatedForNextAttempt())
    }

    func test_Recoverable_BackendServiceCorrectlyForwardsToRecoveryStrategy() async throws {
        let title = "title"
        let subtitle = "subtitle"

        let backendService = BackendService(transportService: MockRecoverableTransportService.protectedService(for: MockObject(title: title, subtitle: subtitle)),
                                            recoveryStrategies: MockAuthorizationRecoveryStrategy())
        let request: Request<MockObject> = .mockRecoverableRequest()

        let mockObject = try await backendService.execute(request: request)
        XCTAssertEqual(mockObject.title, "title")
        XCTAssertEqual(mockObject.subtitle, subtitle)
    }

    func test_Recoverable_BackendServiceCorrectlyForwardsToRecoveryStrategyWhichAlwaysFailsToRecover() async throws {
        let backendService = BackendService(transportService: MockRecoverableTransportService.protectedService(for: MockObject(title: "title", subtitle: "subtitle")),
                                            recoveryStrategies: MockFailureRecoveryStrategy())
        let request: Request<MockObject> = .mockRecoverableRequest()

        do {
            _ = try await backendService.execute(request: request)
            XCTFail("The execute process should throw")

        } catch {
            let transportFailure = try XCTUnwrap(error as? TransportFailure)
            XCTAssertEqual(transportFailure.kind, .clientError(.unauthorized))
        }
    }
}

// MARK: - Request + Convenience
private extension Request {

    static func mockRecoverableRequest<T: Codable>() -> Request<T> {
        return Request<T>(method: .get, url: URL(string: "http://apple.com")!, cachePolicy: .useProtocolCachePolicy, timeout: 1)
    }
}

//
//  RecoverableTests.swift
//  Hyperspace
//
//  Created by Will McGinty on 5/16/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class RecoverableTests: XCTestCase {
    
    // MARK: Properties
    private var backendService: BackendService?
    
    // swiftlint:disable nesting
    struct MockRecoverable: Recoverable {
        typealias ErrorType = AnyError
        var recoveryAttemptCount: UInt = 0
        var maxRecoveryAttempts: UInt? = 1
    }
    
    struct MockAuthorizationRecoveryStrategy: RecoveryStrategy {
        func canAttemptRecovery<R, E: TransportFailureRepresentable>(from error: E, for request: Request<R, E>) -> Bool {
            return true
        }
        
        func attemptRecovery<R, E>(for request: Request<R, E>, with error: E, completion: @escaping (RecoveryDisposition<Request<R, E>>) -> Void) where E: TransportFailureRepresentable {
            guard case let .clientError(clientError) = error.transportError?.code, clientError == .unauthorized, let nextAttempt = request.updatedForNextAttempt() else { return completion(.fail) }
            
            let authorized = nextAttempt.addingHeaders([.authorization: HTTP.HeaderValue(rawValue: "some_access_token")])
            completion(.retry(authorized))
        }
    }
    
    struct MockFailureRecoveryStrategy: RecoveryStrategy {
        func canAttemptRecovery<R, E: TransportFailureRepresentable>(from error: E, for request: Request<R, E>) -> Bool {
            return true
        }
        
        func attemptRecovery<R, E>(for request: Request<R, E>, with error: E, completion: @escaping (RecoveryDisposition<Request<R, E>>) -> Void) where E: TransportFailureRepresentable {
            completion(.fail)
        }
    }
    // swiftlint:enable nesting
    
    class MockRecoverableTransportService: Transporting {
        var responseCreator: (URLRequest) -> TransportResult
        
        init(responseCreator: @escaping (URLRequest) -> TransportResult) {
            self.responseCreator = responseCreator
        }
        
        func execute(request: URLRequest, completion: @escaping (TransportResult) -> Void) {
            DispatchQueue.global().async {
                completion(self.responseCreator(request))
            }
        }
        
        func cancelTask(for request: URLRequest) { /* No op */ }
        func cancelAllTasks() { /* No op */ }
        
        // MARK: Presets
        static func protectedService<T: Encodable>(for object: T) -> MockRecoverableTransportService {
            
            return MockRecoverableTransportService { request -> TransportResult in
                let httpRequest = HTTP.Request()
                if request.allHTTPHeaderFields?["Authorization"] != nil {
                    let data = try! JSONEncoder().encode(object)
                    return .success(TransportSuccess(response: HTTP.Response(request: httpRequest, code: 200, body: data)))
                } else {
                    return .failure(TransportFailure(error: .init(code: .clientError(.unauthorized)), request: httpRequest, response: nil))
                }
            }
        }
    }
    
    // MARK: Tests
    
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
    
    func test_Recoverable_BackendServiceCorrectlyForwardsToRecoveryStrategy() {
        let exp = expectation(description: "backendServiceRecovery")
        let title = "title"
        let subtitle = "subtitle"
        backendService = BackendService(transportService: MockRecoverableTransportService.protectedService(for: MockObject(title: title, subtitle: subtitle)), recoveryStrategies: MockAuthorizationRecoveryStrategy())
        
        let request: Request<MockObject, AnyError> = .mockRecoverableRequest()
        backendService?.execute(request: request) { result in
            switch result {
            case .success(let mockObject):
                XCTAssertEqual(mockObject.title, title)
                XCTAssertEqual(mockObject.subtitle, subtitle)

            case .failure(let error):
                XCTFail("The error should be recoverable: \(error)")
            }

            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_Recoverable_BackendServiceCorrectlyForwardsToRecoveryStrategyWhichAlwaysFailsToRecover() {
        let exp = expectation(description: "backendServiceRecovery")
        backendService = BackendService(transportService: MockRecoverableTransportService.protectedService(for: MockObject(title: "title", subtitle: "subtitle")), recoveryStrategies: MockFailureRecoveryStrategy())
        
        let request: Request<MockObject, AnyError> = .mockRecoverableRequest()
        backendService?.execute(request: request) { result in
            switch result {
            case .success:
                XCTFail("The error should not recoverable!")
                
            case .failure(let error):
                guard let innerError = error.error as? TransportFailure else { return XCTFail("The error that causes the failure should be a TransportFailure .") }
                guard case let .clientError(clientError) = innerError.error.code else { return XCTFail("The error that causes the failure should be a TransportFailure.TransportError.Code.ClientError.") }
                XCTAssertEqual(clientError, .unauthorized)
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

private extension Request {

    static func mockRecoverableRequest<T: Codable>() -> Request<T, AnyError> {
        var request = Request<T, AnyError>(method: .get, url: URL(string: "http://apple.com")!, cachePolicy: .useProtocolCachePolicy, timeout: 1)
        request.maxRecoveryAttempts = 1
        
        return request
    }
}

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
    
    // MARK: Constants
    private static let defaultRequestMethod: HTTP.Method = .get
    private static let defaultURL = URL(string: "http://apple.com")!
    private static let defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    private static let defaultTimeout: TimeInterval = 1.0
    private var backendService: BackendService?
    
    // swiftlint:disable nesting
    struct MockRecoverable: Recoverable {
        typealias ErrorType = AnyError
        var recoveryAttemptCount: UInt = 0
        var maxRecoveryAttempts: UInt? = 1
    }
    
    struct RecoverableRequest<T: Codable>: Request, Recoverable {
        typealias ResponseType = T
        typealias ErrorType = AnyError
        
        var method: HTTP.Method = RecoverableTests.defaultRequestMethod
        var url = RecoverableTests.defaultURL
        var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
        var body: Data?
        var cachePolicy: URLRequest.CachePolicy = RecoverableTests.defaultCachePolicy
        var timeout: TimeInterval = RecoverableTests.defaultTimeout
        var recoveryAttemptCount: UInt = 0
        let maxRecoveryAttempts: UInt? = 1
    }
    
    struct MockAuthorizationRecoveryStrategy: RequestRecoveryStrategy {
        func handleRecoveryAttempt<T: Request & Recoverable>(for request: T, withError error: T.ErrorType, completion: @escaping (RecoveryDisposition<T>) -> Void) {
            guard case let .clientError(clientError) = error.networkServiceError, clientError == .unauthorized, let nextAttempt = request.updatedForNextAttempt() else { return completion(.fail) }
            
            let authorized = nextAttempt.addingHeaders([.authorization: HTTP.HeaderValue(rawValue: "some_access_token")])
            completion(.retry(authorized))
        }
    }
    
    struct MockFailureRecoveryStrategy: RequestRecoveryStrategy {
        func handleRecoveryAttempt<T: Request & Recoverable>(for request: T, withError error: T.ErrorType, completion: @escaping (RecoveryDisposition<T>) -> Void) {
            completion(.fail)
        }
    }
    // swiftlint:enable nesting
    
    class MockRecoverableNetworkService: NetworkServiceProtocol {
        var responseCreator: (URLRequest) -> Result<NetworkServiceSuccess, NetworkServiceFailure>
        
        init(responseCreator: @escaping (URLRequest) -> Result<NetworkServiceSuccess, NetworkServiceFailure>) {
            self.responseCreator = responseCreator
        }
        
        func execute(request: URLRequest, completion: @escaping NetworkServiceCompletion) {
            DispatchQueue.global().async {
                completion(self.responseCreator(request))
            }
        }
        
        func cancelTask(for request: URLRequest) { /* No op */ }
        func cancelAllTasks() { /* No op */ }
        
        // MARK: Presets
        static func protectedService<T: Encodable>(for object: T) -> MockRecoverableNetworkService {
            return MockRecoverableNetworkService { request -> Result<NetworkServiceSuccess, NetworkServiceFailure> in
                if request.allHTTPHeaderFields?["Authorization"] != nil {
                    let data = try! JSONEncoder().encode(object)
                    return .success(NetworkServiceSuccess(data: data, response: HTTP.Response(code: 200, data: nil)))
                } else {
                    return .failure(NetworkServiceFailure(error: .clientError(.unauthorized), response: nil))
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
        backendService = BackendService(networkService: MockRecoverableNetworkService.protectedService(for: MockObject(title: title, subtitle: subtitle)), recoveryStrategy: MockAuthorizationRecoveryStrategy())
        
        backendService?.execute(recoverable: RecoverableRequest<MockObject>()) { result in
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
        backendService = BackendService(networkService: MockRecoverableNetworkService.protectedService(for: MockObject(title: "title", subtitle: "subtitle")), recoveryStrategy: MockFailureRecoveryStrategy())
        
        backendService?.execute(recoverable: RecoverableRequest<MockObject>()) { result in
            switch result {
            case .success:
                XCTFail("The error should not recoverable!")
                
            case .failure(let error):
                guard let innerError = error.error as? NetworkServiceError else { return XCTFail("The error that causes the failure should be a NetworkServiceError.") }
                guard case let .clientError(clientError) = innerError else { return XCTFail("The error that causes the failure should be a NetworkServiceError.ClientError.") }
                XCTAssertEqual(clientError, .unauthorized)
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

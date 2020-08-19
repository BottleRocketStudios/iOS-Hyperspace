//
//  MockBackendService.swift
//  HyperspaceTests
//
//  Created by Adam Brzozowski on 1/30/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation
@testable import Hyperspace

public enum MockBackendServiceError: TransportFailureRepresentable, DecodingFailureRepresentable {

    case networkError(TransportError, HTTP.Response?)
    case dataTransformationError(Error)
    
    public init(transportFailure: TransportFailure) {
        self = .networkError(transportFailure.error, transportFailure.response)
    }

    public init(decodingFailure: DecodingFailure) {
        self = .dataTransformationError(decodingFailure)
    }
    
    public var transportError: TransportError? {
        switch self {
        case .networkError(let error, _): return error
        default: return nil
        }
    }
    
    public var failureResponse: HTTP.Response? {
        switch self {
        case .networkError(_, let response): return response
        case .dataTransformationError: return nil
        }
    }
}

extension MockBackendServiceError: Equatable {
    public static func == (lhs: MockBackendServiceError, rhs: MockBackendServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let lhsError, let lhsResponse), .networkError(let rhsError, let rhsResponse)):
            return lhsError == rhsError && lhsResponse == rhsResponse
        case (.dataTransformationError(let lhsError), .dataTransformationError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

class MockBackendService: BackendServiceProtocol {
    func execute<T, U>(request: Request<T, U>, completion: @escaping (Result<T, U>) -> Void) {
        let failure = TransportFailure(error: .init(code: .timedOut), request: HTTP.Request(urlRequest: request.urlRequest), response: nil)
        completion(.failure(U(transportFailure: failure)))
    }

    func cancelTask(for request: URLRequest) {
        /* No op */
    }
    
    func cancelAllTasks() {
        /* No op */
    }
}

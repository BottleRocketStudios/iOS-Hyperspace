//
//  MockBackendService.swift
//  HyperspaceTests
//
//  Created by Adam Brzozowski on 1/30/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation
@testable import Hyperspace
import Result

public enum MockBackendServiceError: NetworkServiceFailureInitializable, DecodingFailureInitializable {
    case networkError(NetworkServiceError, HTTP.Response?)
    case dataTransformationError(Error)
    
    public init(networkServiceFailure: NetworkServiceFailure) {
        self = .networkError(networkServiceFailure.error, networkServiceFailure.response)
    }
    
    public init(decodingError: DecodingError, data: Data) {
        self = .dataTransformationError(decodingError)
    }
}

extension MockBackendServiceError: Equatable {
    public static func == (lhs: MockBackendServiceError, rhs: MockBackendServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let lhsError, let lhsResponse), .networkError(let rhsError, let rhsResponse)):
            return lhsError == rhsError && lhsResponse == rhsResponse
        case (.dataTransformationError(let lhsError), .dataTransformationError(let rhsError)):
            // TODO: Need to come up with a better way to compare equality in this case
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

struct MockBackendService: BackendServiceProtocol {
    func cancelTask(for request: URLRequest) {
        /* No op */
    }
    
    func cancelAllTasks() {
        /* No op */
    }
    
    func execute<T>(request: T, completion: @escaping (Result<T.ResponseType, T.ErrorType>) -> Void) where T: NetworkRequest {
        let failure = NetworkServiceFailure(error: .timedOut, response: nil)
        completion(Result.failure(T.ErrorType(networkServiceFailure: failure)))
    }
}

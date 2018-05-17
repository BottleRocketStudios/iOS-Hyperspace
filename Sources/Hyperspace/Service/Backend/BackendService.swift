//
//  BackendService.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Result

public class BackendService {
    
    // MARK: - Properties
    
    private let networkService: NetworkServiceProtocol
    public var recoveryStrategy: RequestRecoveryStrategy?
    
    // MARK: - Init
    
    public init(networkService: NetworkServiceProtocol = NetworkService(), recoveryStrategy: RequestRecoveryStrategy? = nil) {
        self.networkService = networkService
        self.recoveryStrategy = recoveryStrategy
    }
    
    deinit {
        cancelAllTasks()
    }
}

// MARK: - BackendService Conformance to BackendServiceProtocol

extension BackendService: BackendServiceProtocol {
    public func execute<T: NetworkRequest>(request: T, completion: @escaping BackendServiceCompletion<T.ResponseType, T.ErrorType>) {
        networkService.execute(request: request.urlRequest) { result in
            switch result {
            case .success(let serviceSuccess):
                BackendServiceHelper.handleResponseData(serviceSuccess.data, for: request, completion: completion)
            case .failure(let serviceFailure):
                BackendServiceHelper.handleNetworkServiceFailure(serviceFailure, completion: completion)
            }
        }
    }
    
    public func execute<T: NetworkRequest & Recoverable>(recoverable request: T, completion: @escaping BackendServiceCompletion<T.ResponseType, T.ErrorType>) {
        execute(request: request) { [weak self] result in
            switch result {
            case .success(let response):
                BackendServiceHelper.handleResponse(response, completion: completion)
                
            case .failure(let error):
                guard let recoveryStrategy = self?.recoveryStrategy else { return completion(.failure(error)) }
                recoveryStrategy.handleRecoveryAttempt(for: request, withError: error) { recoveryDisposition in
                    switch recoveryDisposition {
                    case .fail:
                        BackendServiceHelper.handleErrorFailure(error, completion: completion)
                    case .retry(let recoveredRequest):
                        self?.execute(recoverable: recoveredRequest, completion: completion)
                    }
                }
            }
        }
    }
    
    public func cancelTask(for request: URLRequest) {
        networkService.cancelTask(for: request)
    }
    
    public func cancelAllTasks() {
        networkService.cancelAllTasks()
    }
}

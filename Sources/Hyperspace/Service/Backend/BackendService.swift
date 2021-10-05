//
//  BackendService.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public class BackendService {
    
    // MARK: - Properties
    
    public let transportService: Transporting
    public var recoveryStrategies: [RecoveryStrategy]
    
    // MARK: - Initializer
    
    public init(transportService: Transporting = TransportService(), recoveryStrategies: RecoveryStrategy...) {
        self.transportService = transportService
        self.recoveryStrategies = recoveryStrategies
    }
    
    deinit {
        cancelAllTasks()
    } 
}

// MARK: - BackendService Conformance to BackendServiceProtocol

extension BackendService: BackendServiceProtocol {
    
    public func execute<R, E>(request: Request<R, E>, completion: @escaping (Result<R, E>) -> Void) {
        assert(!(request.method == .get && request.body != nil), "An HTTP GET request should not contain request body data.")
        
        transportService.execute(request: request.urlRequest) { [weak self] result in
            switch result {
            case .success(let success): self?.executeOnMainThread(completion(request.transform(success: success)))
            case .failure(let failure):
                guard let recoveredSuccess = request.recoveryAttemptHandler(failure) else {
                    self?.attemptToRecover(from: E(transportFailure: failure), executing: request, completion: completion)
                    return
                }

                self?.executeOnMainThread(completion(request.transform(success: recoveredSuccess)))
            }
        }
    }

    public func cancelTask(for request: URLRequest) {
        transportService.cancelTask(for: request)
    }
    
    public func cancelAllTasks() {
        transportService.cancelAllTasks()
    }
}

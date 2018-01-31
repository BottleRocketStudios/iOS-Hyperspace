//
//  MockBackendService.swift
//  HyperspaceTests
//
//  Created by Adam Brzozowski on 1/30/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace
import Result

struct MockBackendService: BackendServiceProtocol
{
    func cancelTask(for request: URLRequest) {
        
    }
    
    func cancelAllTasks() {
        
    }
    
    func execute<T>(request: T, completion: @escaping (Result<T.ResponseType, BackendServiceError>) -> Void) where T : NetworkRequest {
        completion( Result.failure(BackendServiceError.networkError(NetworkServiceError.timedOut, nil)))
    }
}

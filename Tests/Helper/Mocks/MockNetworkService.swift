//
//  MockNetworkService.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/29/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace
import Result

class MockNetworkService {
    private(set) var executeCallCount = 0
    private(set) var cancelCallCount = 0
    private(set) var cancelAllTasksCallCount = 0
    private(set) var lastExecutedURLRequest: URLRequest?
    private(set) var lastCancelledURLRequest: URLRequest?
    var responseResult: Result<NetworkServiceSuccess, NetworkServiceFailure>
    
    init(responseResult: Result<NetworkServiceSuccess, NetworkServiceFailure>) {
        self.responseResult = responseResult
    }
}

extension MockNetworkService: NetworkServiceProtocol {
    
    func execute(request: URLRequest, completion: @escaping NetworkServiceCompletion) {
        lastExecutedURLRequest = request
        
        executeCallCount += 1
        
        DispatchQueue.global().async {
            completion(self.responseResult)
        }
    }
    
    func cancelTask(for request: URLRequest) {
        lastCancelledURLRequest = request
        cancelCallCount += 1
    }
    
    func cancelAllTasks() {
        cancelAllTasksCallCount += 1
    }
}

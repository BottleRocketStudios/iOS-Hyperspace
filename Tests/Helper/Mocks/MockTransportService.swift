//
//  MockTransportService.swift
//  Tests
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace

class MockTransportService {
    private(set) var executeCallCount = 0
    private(set) var cancelCallCount = 0
    private(set) var cancelAllTasksCallCount = 0
    private(set) var lastExecutedURLRequest: URLRequest?
    private(set) var lastCancelledURLRequest: URLRequest?
    var responseResult: TransportResult
    
    init(responseResult: TransportResult) {
        self.responseResult = responseResult
    }
}

extension MockTransportService: Transporting {
    
    func execute(request: URLRequest, completion: @escaping (TransportResult) -> Void) {
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

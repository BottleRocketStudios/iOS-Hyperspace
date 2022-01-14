//
//  MockNetworkSessionDataTask.swift
//  Tests
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace

class MockNetworkSessionDataTask: TransportDataTask {
    private(set) var resumeCallCount = 0
    private(set) var cancelCallCount = 0
    private let request: URLRequest
    
    init(request: URLRequest) {
        self.request = request
    }
    
    func resume() {
        resumeCallCount += 1
    }
    
    func cancel() {
        cancelCallCount += 1
    }
}

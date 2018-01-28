//
//  MockNetworkSessionDataTask.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/28/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace

class MockNetworkSessionDataTask: NetworkSessionDataTask {
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

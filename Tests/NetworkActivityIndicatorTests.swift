//
//  NetworkActivityIndicatorTests.swift
//  Hyperspace_Example
//
//  Created by William McGinty on 12/21/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class NetworkActivityIndicatorTests: XCTestCase {
        
    func test_RequestStart_GeneratesControllerResponse() {
        let indicator = MockNetworkActivityIndicator()
        let activityController = NetworkActivityController(indicator: indicator)
        
        activityController.start()
        XCTAssertEqual(activityController.activityCount, 1)
    }
    
    func test_RequestMultithreadedStart_GeneratesControllerResponse() {
        let indicator = MockNetworkActivityIndicator()
        let activityController = NetworkActivityController(indicator: indicator)
        
        DispatchQueue.global().sync { activityController.start() }
        activityController.start()
        
        XCTAssertEqual(activityController.activityCount, 2)
    }
    
    func test_RequestCompletion_GeneratesControllerResponse() {
        let indicator = MockNetworkActivityIndicator()
        let activityController = NetworkActivityController(indicator: indicator)
        
        activityController.start()
        activityController.stop()
        XCTAssertEqual(activityController.activityCount, 0)
    }
    
    func test_RequestCompletion_GeneratesDelayedHideResponse() {
        let indicator = MockNetworkActivityIndicator()
        let activityController = NetworkActivityController(indicator: indicator)
        
        activityController.start()
        activityController.stop()
        
        XCTAssertEqual(activityController.activityCount, 0)
        XCTAssertNotNil(activityController.delayedHide)
    }
    
    func test_RequestCompletion_HideResponseExecutes() {
        let exp = expectation(description: "delayedHideExecutes")
        let indicator = MockNetworkActivityIndicator()
        let activityController = NetworkActivityController(delayInterval: 0.1, indicator: indicator)
        
        activityController.start()
        activityController.stop()
        
        XCTAssertEqual(activityController.activityCount, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertFalse(indicator.isNetworkActivityIndicatorVisible)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.3, handler: nil)
    }
    
    func test_RequestStart_CancelsHideEffectInProgress() {
        let indicator = MockNetworkActivityIndicator()
        let activityController = NetworkActivityController(indicator: indicator)
        
        activityController.start()
        activityController.stop()
        
        XCTAssertEqual(activityController.activityCount, 0)
        XCTAssertNotNil(activityController.delayedHide)
        
        activityController.start()
        
        XCTAssertEqual(activityController.activityCount, 1)
        XCTAssertNil(activityController.delayedHide)
    }
}

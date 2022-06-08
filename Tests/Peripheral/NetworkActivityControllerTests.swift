//
//  NetworkActivityControllerTests.swift
//  Tests
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class NetworkActivityControllerTests: XCTestCase {

    // MARK: - MockNetworkActivityIndicator Subtype
    class MockNetworkActivityIndicator: NetworkActivityIndicatable {
        var isNetworkActivityIndicatorVisible: Bool = false
    }

    // MARK: - Tests
    func test_RequestStart_GeneratesControllerResponse() async {
        let indicator = MockNetworkActivityIndicator()
        let activityController = NetworkActivityController(indicator: indicator)

        await activityController.start()
        let activityCount = await activityController.activityCount
        XCTAssertEqual(activityCount, 1)
    }

    func test_RequestMultithreadedStart_GeneratesControllerResponse() async {
        let indicator = MockNetworkActivityIndicator()
        let activityController = NetworkActivityController(indicator: indicator)

        await activityController.start()
        await withTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask { await activityController.start() }
            taskGroup.addTask { await activityController.start() }
            taskGroup.addTask { await activityController.start() }
        }

        let activityCount = await activityController.activityCount
        XCTAssertEqual(activityCount, 4)
    }

    func test_RequestCompletion_GeneratesControllerResponse() async {
        let indicator = MockNetworkActivityIndicator()
        let activityController = NetworkActivityController(indicator: indicator)

        await activityController.start()
        await activityController.stop()

        let activityCount = await activityController.activityCount
        XCTAssertEqual(activityCount, 0)
    }

    func test_RequestCompletion_GeneratesDelayedHideResponse() async {
        let indicator = MockNetworkActivityIndicator()
        let activityController = NetworkActivityController(indicator: indicator)

        await activityController.start()
        await activityController.stop()

        let activityCount = await activityController.activityCount
        let delayedHide = await activityController.delayedHide
        XCTAssertEqual(activityCount, 0)
        XCTAssertNotNil(delayedHide)
    }

    func test_RequestCompletion_HideResponseExecutes() async throws {
        let delayInterval: TimeInterval = 0.1
        let indicator = MockNetworkActivityIndicator()
        let activityController = NetworkActivityController(delayInterval: delayInterval, indicator: indicator)

        await activityController.start()
        await activityController.stop()

        let activityCount = await activityController.activityCount
        XCTAssertEqual(activityCount, 0)

        try await Task.sleep(seconds: delayInterval * 2.0)
        XCTAssertFalse(indicator.isNetworkActivityIndicatorVisible)
    }

    func test_RequestStart_CancelsHideEffectInProgress() async {
        let indicator = MockNetworkActivityIndicator()
        let activityController = NetworkActivityController(indicator: indicator)

        await activityController.start()
        await activityController.stop()

        let activityCount = await activityController.activityCount
        let delayedHide = await activityController.delayedHide
        XCTAssertEqual(activityCount, 0)
        XCTAssertNotNil(delayedHide)

        await activityController.start()

        let newActivityCount = await activityController.activityCount
        let newDelayedHide = await activityController.delayedHide
        XCTAssertEqual(newActivityCount, 1)
        XCTAssertNil(newDelayedHide)
    }
}

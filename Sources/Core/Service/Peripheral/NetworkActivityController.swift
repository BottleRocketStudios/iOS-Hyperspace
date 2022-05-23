//  NetworkActivityIndicatable.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents an object that can indicate to the user that network activity is currently taking place.
public protocol NetworkActivityIndicatable {
    var isNetworkActivityIndicatorVisible: Bool { get set }
}

/// Manages and records the number of active network requests in relation to their effect on network indicators.
actor NetworkActivityController {

    // MARK: - Properties
    let delayInterval: TimeInterval
    private(set) var indicator: NetworkActivityIndicatable

    private(set) var activityCount = 0
    private(set) var delayedHide: Task<Void, Never>?

    // MARK: - Initializers
    init(delayInterval: TimeInterval = 1.0, indicator: NetworkActivityIndicatable) {
        self.delayInterval = delayInterval
        self.indicator = indicator
    }

    // MARK: - Interface

    /// Indicate to the controller that a new network request has started.
    func start() {
        activityCount += 1
        update()
    }

    /// Indicate to the controller that a network request has ended (through cancellation or completion)
    func stop() {
        activityCount -= 1
        update()
    }
}

// MARK: - Helper
private extension NetworkActivityController {

    func update() {
        guard activityCount <= 0 else {
            // If there is 1+ activities, immediately configure the indicator as visible
            return configureIndicator(visible: true)
        }

        // If there is no activity, wait the specified delay period before configuring the indicator as not visible
        delayedHide = Task {
            try? await Task.sleep(seconds: delayInterval)

            if !Task.isCancelled {
                self.configureIndicator(visible: false)
            }
        }
    }

    func configureIndicator(visible: Bool) {
        delayedHide?.cancel()
        delayedHide = nil

        // Only need to set the visibility of the indicator if it has changed
        if indicator.isNetworkActivityIndicatorVisible != visible {
            indicator.isNetworkActivityIndicatorVisible = visible
        }
    }
}

// MARK: - Task Convenience
private extension Task where Success == Never, Failure == Never {

    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

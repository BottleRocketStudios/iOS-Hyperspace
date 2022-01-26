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

/// Represents an object that is capable of recording the state of network requests and forwarding that state to the corresponding indicator.
protocol NetworkActivityObservable {
    func start()
    func stop()

    var activityCount: Int { get }
    var indicator: NetworkActivityIndicatable { get }
}

/// Manages and records the number of active network requests in relation to their effect on network indicators.
class NetworkActivityController: NetworkActivityObservable {

    // MARK: - Properties
    let delayInterval: TimeInterval
    private(set) var indicator: NetworkActivityIndicatable

    private let queue = DispatchQueue(label: "com.bottlerocketstudios.hyperspace.networkactivityindicator", qos: .userInitiated)
    private(set) var delayedHide: DispatchWorkItem?
    private(set) var activityCount = 0

    // MARK: - Initializers
    public init(delayInterval: TimeInterval = 1.0, indicator: NetworkActivityIndicatable) {
        self.delayInterval = delayInterval
        self.indicator = indicator
    }

    /// Indicate to the controller that a new network request has started.
    func start() {
        queue.sync {
            self.activityCount += 1
            self.update()
        }
    }

    /// Indicate to the controller that a network request has ended (through cancellation or completion)
    func stop() {
        queue.sync {
            self.activityCount -= 1
            self.update()
        }
    }
}

// MARK: - Helper
private extension NetworkActivityController {

    func update() {
        guard activityCount <= 0 else { return configureIndicator(visible: true) }

        let workItem = DispatchWorkItem {
            self.configureIndicator(visible: false)
        }

        delayedHide = workItem
        queue.asyncAfter(deadline: .now() + delayInterval, execute: workItem)
    }

    func configureIndicator(visible: Bool) {
        delayedHide?.cancel()
        delayedHide = nil

        DispatchQueue.main.async {
            // Only need to set the visibility of the indicator if it has changed
            if self.indicator.isNetworkActivityIndicatorVisible != visible {
                self.indicator.isNetworkActivityIndicatorVisible = visible
            }
        }
    }
}

//
//  NetworkSessionDataTask.swift
//  Hyperspace
//
//  Created by Tyler Milner on 7/10/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Represents a data task that can be executed or cancelled. Modeled after URLSessionDataTask to allow for injecting mock data tasks into a NetworkSession.
public protocol NetworkSessionDataTask {
    func resume()
    func cancel()
}

// MARK: - URLSessionDataTask Conformance to NetworkSessionDataTask

extension URLSessionDataTask: NetworkSessionDataTask { }

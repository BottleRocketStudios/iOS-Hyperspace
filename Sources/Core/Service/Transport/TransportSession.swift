//
//  TransportSession.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public typealias TransportSessionConfiguration = URLSessionConfiguration
public typealias TransportTaskDelegate = URLSessionTaskDelegate

/// Represents something that can execute a URLRequest to return a TransportDataTask. Modeled after URLSession to allow for injecting mock sessions into a BackendService.
public protocol TransportSession {
    var configuration: TransportSessionConfiguration { get }

    func data(for request: URLRequest, delegate: TransportTaskDelegate?) async throws -> (Data, URLResponse)
}

// MARK: - URLSession Conformance to TransportSession
extension URLSession: TransportSession { }

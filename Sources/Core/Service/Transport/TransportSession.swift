//
//  TransportSession.swift
//  Hyperspace
////  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

// MARK: - TransportDataTask

@available(*, renamed: "TransportDataTask")
public typealias NetworkSessionDataTask = TransportDataTask

/// Represents a data task that can be executed or cancelled. Modeled after URLSessionDataTask to allow for injecting mock data tasks into a TransportSession.
public protocol TransportDataTask {
    func resume()
    func cancel()
}

// MARK: - URLSessionDataTask Conformance to TransportDataTask

extension URLSessionDataTask: TransportDataTask { }

@available(*, renamed: "TransportSession")
public typealias NetworkSession = TransportSession

/// Represents something that can execute a URLRequest to return a TransportDataTask. Modeled after URLSession to allow for injecting mock sessions into a BackendService.
public protocol TransportSession {
    var configuration: URLSessionConfiguration { get }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> TransportDataTask
}

// MARK: - URLSession Conformance to TransportSession

extension URLSession: TransportSession {
    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> TransportDataTask {
        return (dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask) as TransportDataTask
    }
}

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

    @available(iOS, deprecated: 15.0)
    @available(tvOS, deprecated: 15.0)
    @available(macOS, deprecated: 12.0)
    @available(watchOS, deprecated: 8.0)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func data(for request: URLRequest, delegate: TransportTaskDelegate?) async throws -> (Data, URLResponse)
}

// MARK: - URLSession Conformance to TransportSession
extension URLSession: TransportSession {

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            return try await data(for: request, delegate: nil)
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                let task = self.dataTask(with: request) { data, response, error in
                    guard let data = data, let response = response else {
                        let error = error ?? URLError(.badServerResponse)
                        return continuation.resume(throwing: error)
                    }

                    continuation.resume(returning: (data, response))
                }

                task.resume()
            }
        }
    }
}

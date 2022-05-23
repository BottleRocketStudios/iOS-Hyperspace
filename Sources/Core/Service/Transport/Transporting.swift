//
//  Transporting.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

// MARK: - Transporting

/// Represents something that can execute a URLRequest.
public protocol Transporting {
    
    /// Executes the `URLRequest`, calling the provided completion block when complete.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` to execute.
    ///   - completion: The completion block to be invoked when request execution is complete.
    func execute(request: URLRequest, delegate: TransportTaskDelegate?) async throws -> TransportResult
}

// MARK: - TransportService

/// Adopts the `Transporting` protocol to perform HTTP communication via the execution of URLRequests.
public actor TransportService {

    // MARK: - Properties
    let session: TransportSession
    let networkActivityController: NetworkActivityController?

    // MARK: - Initializers
    public init(session: TransportSession = URLSession.shared, networkActivityIndicatable: NetworkActivityIndicatable? = nil) {
        self.session = session
        self.networkActivityController = networkActivityIndicatable.map { NetworkActivityController(indicator: $0) }
    }

    public convenience init(sessionConfiguration: TransportSessionConfiguration, networkActivityIndicatable: NetworkActivityIndicatable? = nil) {
        self.init(session: URLSession(configuration: sessionConfiguration), networkActivityIndicatable: networkActivityIndicatable)
    }
}

// MARK: - TransportService + Transporting
extension TransportService: Transporting {

    public func execute(request: URLRequest, delegate: TransportTaskDelegate? = nil) async throws -> TransportResult {
        startTransportTask()
        let (data, urlResponse) = try await session.data(for: request, delegate: delegate)
        finishTransportTask()

        try Task.checkCancellation()

        guard let httpURLResponse = urlResponse as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        let response = HTTP.Response(request: .init(urlRequest: request), httpURLResponse: httpURLResponse, body: data)
        return response.transportResult
    }
}

// MARK: - Helper
private extension TransportService {

    func startTransportTask() {
        Task {
            await networkActivityController?.start()
        }
    }

    func finishTransportTask() {
        Task {
            await networkActivityController?.stop()
        }
    }
}

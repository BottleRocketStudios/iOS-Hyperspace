//
//  TransportService.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

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
    
    public convenience init(sessionConfiguration: URLSessionConfiguration, networkActivityIndicatable: NetworkActivityIndicatable? = nil) {
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
        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            //todo: better error handling
            throw TransportError(code: .unknownError)
        }

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

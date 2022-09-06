//
//  MockNetworkSession.swift
//  Tests
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace

class MockTransportSession {

    private let responseStatusCode: Int?
    private let responseData: Data?
    private let error: Error?

    init(responseStatusCode: Int?, responseData: Data?, error: Error?) {
        self.responseStatusCode = responseStatusCode
        self.responseData = responseData
        self.error = error
    }
}

extension MockTransportSession: TransportSession {

    var configuration: URLSessionConfiguration { return .default }

    func data(for request: URLRequest, delegate: TransportTaskDelegate?) async throws -> (Data, URLResponse) {
        guard let url = request.url else { fatalError("No \(URL.self) provided") }

        let response: URLResponse? = responseStatusCode.flatMap { HTTPURLResponse(url: url, statusCode: $0, httpVersion: "HTTP/1.1", headerFields: nil) }

        switch (responseData, response, error) {
        case (.some(let data), .some(let response), _): return (data, response)
        case (_, _, .some(let error)): throw error
        default: fatalError("Invalid combination of data, response and error provided.")
        }
    }
}

//
//  TransportService.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Adopts the `Transporting` to perform HTTP communication via the execution of URLRequests.
public class TransportService {
    
    // MARK: - Properties
    
    let session: TransportSession
    private(set) var networkActivityController: NetworkActivityController?
    private var tasks = [URLRequest: TransportDataTask]()
    
    // MARK: - Initializer
    
    public init(session: TransportSession = URLSession.shared, networkActivityIndicatable: NetworkActivityIndicatable? = nil) {
        self.session = session
        self.networkActivityController = networkActivityIndicatable.map { NetworkActivityController(indicator: $0) }
    }
    
    public convenience init(sessionConfiguration: URLSessionConfiguration, networkActivityIndicatable: NetworkActivityIndicatable? = nil) {
        self.init(session: URLSession(configuration: sessionConfiguration), networkActivityIndicatable: networkActivityIndicatable)
    }
    
    deinit {
        cancelAllTasks()
    }
}

// MARK: - TransportService Conformance to Transporting

extension TransportService: Transporting {
    
    public func execute(request: URLRequest, completion: @escaping (TransportResult) -> Void) {
        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
            self?.networkActivityController?.stop()
            self?.handle(data: data, response: response, error: error, for: HTTP.Request(urlRequest: request), completion: completion)
        }
        
        tasks[request] = task
        task.resume()
        
        networkActivityController?.start()
    }
    
    public func cancelTask(for request: URLRequest) {
        tasks[request]?.cancel()
    }
    
    public func cancelAllTasks() {
        tasks.forEach { cancelTask(for: $0.key) }
    }
}

// MARK: - Helper

private extension TransportService {

    func handle(data: Data?, response: URLResponse?, error: Error?, for request: HTTP.Request, completion: @escaping (TransportResult) -> Void) {
        switch (data, response, error) {
        case let (responseData, .some(urlResponse as HTTPURLResponse), .none):
            // A response and no client error was received, rely on the response status code to determine the result
            let httpResponse = HTTP.Response(request: request, httpURLResponse: urlResponse, body: responseData)
            completion(httpResponse.transportResult)

        case let (responseData, urlResponse as HTTPURLResponse?, .some(clientError)):
            // A client error was received, we know this response resulted in a failure
            let httpResponse = urlResponse.map { HTTP.Response(request: request, httpURLResponse: $0, body: responseData) }
            let transportFailure = TransportFailure(error: TransportError(clientError: clientError), request: request, response: httpResponse)
            completion(.failure(transportFailure))

        default:
            // An unexpected response was received, we don't know what went wrong
            completion(.failure(TransportFailure(error: TransportError(clientError: error), request: request, response: nil)))
        }
    }
}

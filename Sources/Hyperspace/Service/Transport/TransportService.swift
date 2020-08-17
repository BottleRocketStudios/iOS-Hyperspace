//
//  TransportService.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

//  TODO: Future functionality:
//          - Provide an implementation that uses the URLSession delegate methods.
//          - Look into using an ephemeral URLSession as the default TransportSession since it requires no cleanup.

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
            self?.handle(data: data, response: response, error: error, completion: completion)
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

    func handle(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (TransportResult) -> Void) {
        switch (data, response, error) {
        case let (responseData, .some(urlResponse as HTTPURLResponse), .none):
            let httpResponse = HTTP.Response(httpURLResponse: urlResponse, data: responseData)
            completion(httpResponse.transportResult)

        case let (responseData, urlResponse as HTTPURLResponse?, .some(clientError)):
            let transportFailure = TransportFailure(error: TransportError(clientError: clientError), response: urlResponse.map { HTTP.Response(httpURLResponse: $0, data: responseData) })
            completion(.failure(transportFailure))

        default:
            completion(.failure(TransportFailure(error: TransportError(code: .unknownError), response: nil)))
        }
    }
}

//
//  TransportService.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

//  TODO: Future functionality:
//          - Provide an implementation that uses the URLSession delegate methods.
//          - Look into using an ephemeral URLSession as the default NetworkSession since it requires no cleanup.

import Foundation

/// Adopts the `Transporting` to perform HTTP communication via the execution of URLRequests.
public class TransportService {
    
    // MARK: - Properties
    
    private let session: NetworkSession
    private var networkActivityController: NetworkActivityController?
    private var tasks = [URLRequest: NetworkSessionDataTask]()
    
    // MARK: - Initializer
    
    public init(session: NetworkSession = URLSession.shared, networkActivityIndicatable: NetworkActivityIndicatable? = nil) {
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
            
            switch (data, response, error) {
            case let (.some(responseData), .some(urlResponse as HTTPURLResponse), .none):
                let httpResponse = HTTP.Response(httpURLResponse: urlResponse, data: responseData)
                completion(httpResponse.transportResult)
                
            case let (responseData, urlResponse as HTTPURLResponse, .some(clientError)):
                let transportFailure = TransportFailure(error: TransportError(clientError: clientError), response: HTTP.Response(httpURLResponse: urlResponse, data: responseData))
                completion(.failure(transportFailure))
                
            default:
                completion(.failure(TransportFailure(error: TransportError(code: .unknownError), response: nil)))            }
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
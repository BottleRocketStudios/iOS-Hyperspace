//
//  NetworkService.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

//
//  TODO: Future functionality:
//          - Provide an implementation that uses the URLSession delegate methods.
//          - Provide an easy way to retry a request.
//          - Look into providing hooks to allow for custom parsing of status codes.
//                  Example:
//                      - Handling of 401 Unauthorized responses - execute a request to reobtain a valid auth token and then retry the request.
//                      - Bad APIs that return a 200 response when an error actually ocurred
//          - Look into using an ephemeral URLSession as the default NetworkSession since it requires no cleanup.
//          - Look into initialization using a session configuration rather than a NetworkSession.
//

import Foundation

/// Adopts the NetworkServiceProtocol to perform HTTP communication via the execution of URLRequests.
public class NetworkService {
    
    // MARK: - Properties
    
    private let session: NetworkSession
    private var networkActivityController: NetworkActivityController?
    private var tasks = [URLRequest: NetworkSessionDataTask]()
    
    // MARK: - Init
    
    public init(session: NetworkSession = URLSession.shared, networkActivityController: NetworkActivityController? = nil) {
        self.session = session
        self.networkActivityController = networkActivityController
    }
    
    public convenience init(session: NetworkSession = URLSession.shared, networkActivityIndicatable: NetworkActivityIndicatable) {
        let networkActivityController = NetworkActivityController(indicator: networkActivityIndicatable)
        self.init(session: session, networkActivityController: networkActivityController)
    }
    
    deinit {
        cancelAllTasks()
    }
}

// MARK: - NetworkService Conformance to NetworkServiceProtocol

extension NetworkService: NetworkServiceProtocol {
    public func execute(request: URLRequest, completion: @escaping NetworkServiceCompletion) {
        let task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            self?.networkActivityController?.stop()
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                let responseError = self?.invalidHTTPResponseError(for: error) ?? .unknownError
                let result = NetworkServiceFailure(error: responseError, response: nil)
                
                completion(.failure(result))
                return
            }
            
            let httpResponse = HTTP.Response(code: statusCode, data: data)
            
            switch httpResponse.status {
            case .unknown:
                let result = NetworkServiceFailure(error: .unknownStatusCode, response: httpResponse)
                completion(.failure(result))
            case .success:
                guard let data = data else {
                    let result = NetworkServiceFailure(error: .noData, response: httpResponse)
                    completion(.failure(result))
                    return
                }
                
                let result = NetworkServiceSuccess(data: data, response: httpResponse)
                completion(.success(result))
            case .redirection:
                let result = NetworkServiceFailure(error: .redirection, response: httpResponse)
                completion(.failure(result))
            case .clientError(let clientError):
                let result = NetworkServiceFailure(error: .clientError(clientError), response: httpResponse)
                completion(.failure(result))
            case .serverError(let serverError):
                let result = NetworkServiceFailure(error: .serverError(serverError), response: httpResponse)
                completion(.failure(result))
            }
        })
        
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

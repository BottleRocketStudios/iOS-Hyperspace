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
import Result

/// Adopts the NetworkServiceProtocol to perform HTTP communication via the execution of URLRequests.
public class NetworkService {
    
    // MARK: - Properties
    
    private let session: NetworkSession
    private var tasks = [URLRequest: NetworkSessionDataTask]()
    
    // MARK: - Init
    
    public init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }
    
    deinit {
        cancelAllTasks()
    }
}

// MARK: - NetworkService Conformance to NetworkServiceProtocol

extension NetworkService: NetworkServiceProtocol {
    public func execute(request: URLRequest, completion: @escaping NetworkServiceCompletion) {
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                completion(NetworkServiceHelper.networkServiceResult(for: error))
                return
            }
            
            let httpResponse = HTTP.Response(code: statusCode, data: data)
            let result = NetworkServiceHelper.networkServiceResult(for: httpResponse)
            completion(result)
        }
        
        tasks[request] = task
        task.resume()
    }
    
    public func cancelTask(for request: URLRequest) {
        tasks[request]?.cancel()
    }
    
    public func cancelAllTasks() {
        tasks.forEach { cancelTask(for: $0.key) }
    }
}

/// A small helper struct which deals with the conversion of Data, URLResponse and Error objects to NetworkService successes and failures.
public struct NetworkServiceHelper {
    
    /// Used to convert a client error, such as those returned by a NetworkSessionDataTask, into a NetworkServiceResult.
    ///
    /// - Parameter clientError: The error returned by the NetworkSessionDataTask.
    /// - Returns: The outcome NetworkServiceResult dictated by the error.
    public static func networkServiceResult(for clientError: Error?) -> NetworkServiceResult {
        let responseError = invalidHTTPResponseError(for: clientError)
        return .failure(NetworkServiceFailure(error: responseError, response: nil))
    }
    
    /// Used to convert a valid HTTP.Response object, such as those returned by a NetworkSessionDataTask, into a NetworkServiceResult.
    ///
    /// - Parameter response: The HTTP.Response object returned by the NetworkSessionDataTask.
    /// - Returns: The outcome NetworkServiceResult dictated by the HTTP.Response.
    public static func networkServiceResult(for response: HTTP.Response) -> NetworkServiceResult {
        switch response.status {
        case .unknown:
            return .failure(NetworkServiceFailure(error: .unknownStatusCode, response: response))
        case .success:
            guard let data = response.data else {
                return .failure(NetworkServiceFailure(error: .noData, response: response))
            }
            
            return .success(NetworkServiceSuccess(data: data, response: response))
        case .redirection:
            return .failure(NetworkServiceFailure(error: .redirection, response: response))
        case .clientError(let clientError):
            return .failure(NetworkServiceFailure(error: .clientError(clientError), response: response))
        case .serverError(let serverError):
            return .failure(NetworkServiceFailure(error: .serverError(serverError), response: response))
        }
    }
}

private extension NetworkServiceHelper {
    
    private static func invalidHTTPResponseError(for error: Error?) -> NetworkServiceError {
        let networkError: NetworkServiceError = (error as NSError?).flatMap {
            switch ($0.domain, $0.code) {
            case (NSURLErrorDomain, NSURLErrorNotConnectedToInternet):
                return .noInternetConnection
            case (NSURLErrorDomain, NSURLErrorTimedOut):
                return .timedOut
            case (NSURLErrorDomain, NSURLErrorCancelled):
                return .cancelled
            default:
                return .unknownError
            }
            } ?? .unknownError
        
        return networkError
    }
}

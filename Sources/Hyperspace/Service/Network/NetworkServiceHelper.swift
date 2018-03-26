//
//  NetworkServiceHelper.swift
//  Hyperspace
//
//  Created by Tyler Milner on 3/25/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// A small helper struct which deals with the conversion of Data, URLResponse and Error objects to NetworkService successes and failures.
public struct NetworkServiceHelper {
    
    /// Used to convert a client error, such as those returned by a NetworkSessionDataTask, into a NetworkServiceResult.
    ///
    /// - Parameter clientError: The error returned by the NetworkSessionDataTask.
    /// - Returns: The outcome NetworkServiceResult dictated by the error.
    public static func networkServiceFailure(for clientError: Error?) -> NetworkServiceFailure {
        let responseError = invalidHTTPResponseError(for: clientError)
        return NetworkServiceFailure(error: responseError, response: nil)
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

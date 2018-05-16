//
//  BackendServiceHelper.swift
//  Hyperspace
//
//  Created by Earl Gaspard on 5/9/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Result

/// A helper struct for use with BackendService.
public struct BackendServiceHelper {
    
    /// Attempts to transform response data into the associated response model.
    ///
    /// - Parameters:
    ///   - data: The raw Data retrieved from the network.
    ///   - request: The NetworkRequest that will be used to transform the Data.
    ///   - completion: The completion block to invoke when execution has finished.
    public static func handleResponseData<T: NetworkRequest>(_ data: Data, for request: T, completion: @escaping BackendServiceCompletion<T.ResponseType, T.ErrorType>) {
        let transformResult = request.transformData(data)
        
        DispatchQueue.main.async {
            switch transformResult {
            case .success(let transformedObject):
                completion(.success(transformedObject))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public static func handleResponse<T, U>(_ response: T, completion: @escaping BackendServiceCompletion<T, U>) {
        DispatchQueue.main.async {
            completion(.success(response))
        }
    }
    
    public static func handleNetworkServiceFailure<T, U: NetworkServiceFailureInitializable>(_ serviceFailure: NetworkServiceFailure, completion: @escaping BackendServiceCompletion<T, U>) {
        DispatchQueue.main.async {
            completion(.failure(U(networkServiceFailure: serviceFailure)))
        }
    }
    
    public static func handleErrorFailure<T, U>(_ error: U, completion: @escaping BackendServiceCompletion<T, U>) {
        DispatchQueue.main.async {
            completion(.failure(error))
        }
    }
}

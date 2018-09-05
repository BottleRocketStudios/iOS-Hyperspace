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
    ///   - response: The HTTP.Response retrieved from the network.
    ///   - request: The Request that will be used to transform the Data.
    ///   - completion: The completion block to invoke when execution has finished.
    public static func handleResponse<T: Request>(_ response: HTTP.Response, for request: T, completion: @escaping BackendServiceCompletion<T.ResponseType, T.ErrorType>) {
        let transformResult = request.transformData(response.data ?? Data())
        
        executeOnMain {
            switch transformResult {
            case .success(let transformedObject):
                completion(.success(transformedObject), response)
            case .failure(let error):
                completion(.failure(error), response)
            }
        }
    }
    
    public static func handleResponse<T, U>(_ response: T, completion: @escaping BackendServiceCompletion<T, U>) {
        executeOnMain {
            completion(.success(response), nil)
        }
    }
    
    public static func handleNetworkServiceFailure<T, U: NetworkServiceFailureInitializable>(_ serviceFailure: NetworkServiceFailure, completion: @escaping BackendServiceCompletion<T, U>) {
        executeOnMain {
            completion(.failure(U(networkServiceFailure: serviceFailure)), nil)
        }
    }
    
    public static func handleErrorFailure<T, U>(_ error: U, completion: @escaping BackendServiceCompletion<T, U>) {
        executeOnMain {
            completion(.failure(error), nil)
        }
    }
    
    private static func executeOnMain(block: @escaping () -> Void) {
        guard !Thread.isMainThread else { return block() }
        DispatchQueue.main.async {
            block()
        }
    }
}

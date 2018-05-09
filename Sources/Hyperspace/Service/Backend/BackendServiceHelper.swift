//
//  BackendServiceHelper.swift
//  Hyperspace
//
//  Created by Earl Gaspard on 5/9/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// A helper struct for use with BackendService.
public struct BackendServiceHelper {
    
    /// Attempts to transform response data into the associated response model.
    ///
    /// - Parameters:
    ///   - data: The raw Data retrieved from the network.
    ///   - request: The NetworkRequest that will be used to transform the Data.
    ///   - completion: The completion block to invoke when execution has finished.
    public static func handleResponseData<T: NetworkRequest>(_ data: Data, for request: T, completion: @escaping BackendServiceCompletion<T.ResponseType>) {
        let transformResult = request.transformData(data)
        
        DispatchQueue.main.async {
            switch transformResult {
            case .success(let transformedObject):
                completion(.success(transformedObject))
            case .failure(let error):
                completion(.failure(.dataTransformationError(error)))
            }
        }
    }
}

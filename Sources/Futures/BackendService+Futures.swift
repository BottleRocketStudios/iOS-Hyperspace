//
//  BackendService+Futures.swift
//  Hyperspace-iOS
//
//  Created by Pranjal Satija on 1/10/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import BrightFutures

extension BackendServiceProtocol {
    /// Executes the Request, returning a Future when finished.
    ///
    /// - Parameters:
    ///   - request: The Request to be executed.
    /// - Returns: A Future<T.ResponseType> that resolves to the request's response type.
    public func execute<T: Request>(request: T) -> Future<T.ResponseType, T.ErrorType> {
        let promise = Promise<T.ResponseType, T.ErrorType>()
        
        execute(request: request) { result in
            promise.complete(result)
        }
        
        return promise.future
    }
}

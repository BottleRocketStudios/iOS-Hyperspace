//
//  AnyError+Request.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 9/21/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Result

// MARK: - AnyError Conformance to NetworkServiceInitializable

extension AnyError: NetworkServiceFailureInitializable {
    
    public init(networkServiceFailure: NetworkServiceFailure) {
        self.init(networkServiceFailure.error)
    }
    
    public var networkServiceError: NetworkServiceError {
        return (error as? NetworkServiceError) ?? .unknownError
    }
    
    public var failureResponse: HTTP.Response? {
        return nil
    }
}

// MARK: - AnyError Conformance to DecodingFailureInitializable

extension AnyError: DecodingFailureInitializable {
    public init(error: DecodingError, decoding: Decodable.Type, data: Data) {
        self.init(error)
    }
}

// MARK: - AnyError Conformance to BackendServiceErrorInitializable

@available(*, deprecated: 2.0, message: "Utilize Request.ErrorType to initialize a custom error type instead.")
extension AnyError: BackendServiceErrorInitializable {
    public init(_ backendServiceError: BackendServiceError) {
        self.init(backendServiceError as Error)
    }
}

//
//  AnyError+Request.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 9/21/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

// Testing Danger...

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

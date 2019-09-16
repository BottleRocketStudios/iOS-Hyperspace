//
//  AnyError.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 3/25/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public struct AnyError: Swift.Error {
    
    // MARK: Properties
    
    public let error: Swift.Error
    
    // MARK: Initializers
    
    public init(_ error: Swift.Error) {
        guard let anyError = error as? AnyError else { self.error = error; return }
        self = anyError
    }
}

// MARK: AnyError Conformance to CustomStringConvertible

extension AnyError: CustomStringConvertible {
    
    public var description: String {
        return String(describing: error)
    }
}

// MARK: AnyError Conformance to LocalizedError

extension AnyError: LocalizedError {
    
    public var errorDescription: String? {
        return error.localizedDescription
    }
    
    public var failureReason: String? {
        return (error as? LocalizedError)?.failureReason
    }
    
    public var helpAnchor: String? {
        return (error as? LocalizedError)?.helpAnchor
    }
    
    public var recoverySuggestion: String? {
        return (error as? LocalizedError)?.recoverySuggestion
    }
}

// MARK: - AnyError Conformance to NetworkServiceInitializable

extension AnyError: NetworkServiceFailureInitializable {
    
    public init(networkServiceFailure: NetworkServiceFailure) {
        self.init(networkServiceFailure)
    }
    
    public var networkServiceError: NetworkServiceError {
        return (error as? NetworkServiceFailure)?.error ?? .unknownError(error)
    }
    
    public var failureResponse: HTTP.Response? {
        return (error as? NetworkServiceFailure)?.response
    }
}

// MARK: - AnyError Conformance to DecodingFailureInitializable

extension AnyError: DecodingFailureInitializable {
    public init(error: DecodingError, decoding: Decodable.Type, data: Data) {
        self.init(error)
    }
}

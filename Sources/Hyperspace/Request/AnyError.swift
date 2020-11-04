//
//  AnyError.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 3/25/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public struct AnyError: Swift.Error {
    
    // MARK: - Properties
    
    public let error: Swift.Error
    
    // MARK: - Initializers
    
    public init(_ error: Swift.Error) {
        guard let anyError = error as? AnyError else { self.error = error; return }
        self = anyError
    }
}

// MARK: - AnyError Conformance to CustomStringConvertible

extension AnyError: CustomStringConvertible {
    
    public var description: String {
        return String(describing: error)
    }
}

// MARK: - AnyError Conformance to LocalizedError

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

// MARK: - AnyError Conformance to DecodingFailureRepresentable

extension AnyError: DecodingFailureRepresentable {

    public init(decodingFailure: DecodingFailure) {
        self.init(decodingFailure)
    }

    public init(transportFailure: TransportFailure) {
        self.init(transportFailure)
    }
   
    public var transportError: TransportError? {
        return (error as? TransportFailure)?.error ?? TransportError(code: .unknownError)
    }
    
    public var failureResponse: HTTP.Response? {
        return (error as? TransportFailure)?.response
    }
}

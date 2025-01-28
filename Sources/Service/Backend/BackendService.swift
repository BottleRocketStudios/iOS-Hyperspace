//
//  BackendService.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public class BackendService {
    
    // MARK: - Properties
    public let transportService: any Transporting
    public var preparationStrategies: [any PreparationStrategy]
    public var recoveryStrategies: [any RecoveryStrategy]

    // MARK: - Initializers
    public convenience init(transportService: any Transporting = TransportService(), preparationStrategies: any PreparationStrategy..., recoveryStrategies: any RecoveryStrategy...) {
        self.init(transportService: transportService, preparationStrategies: preparationStrategies, recoveryStrategies: recoveryStrategies)
    }

    @available(*, deprecated, renamed: "BackendService.init(transportService:preparationStrategies:recoveryStrategies:)")
    public convenience init(transportService: any Transporting = TransportService(), recoveryStrategies: [any RecoveryStrategy]) {
        self.init(transportService: transportService, preparationStrategies: [], recoveryStrategies: recoveryStrategies)
    }

    public init(transportService: any Transporting = TransportService(), preparationStrategies: [any PreparationStrategy], recoveryStrategies: [any RecoveryStrategy]) {
        self.transportService = transportService
        self.preparationStrategies = preparationStrategies
        self.recoveryStrategies = recoveryStrategies
    }
}

// MARK: - BackendService + BackendServicing
extension BackendService: BackendServicing {

    @available(iOS, deprecated: 15.0)
    @available(tvOS, deprecated: 15.0)
    @available(macOS, deprecated: 12.0)
    @available(watchOS, deprecated: 8.0)
    public func execute<R>(request: Request<R>) async throws -> R {
        assert(!(request.method == .get && request.body != nil), "An HTTP GET request should not contain request body data.")

        let preparedRequest = try await prepare(toExecute: request)

        do {
            let success = try await transportService.execute(request: preparedRequest.urlRequest)
            try preparedRequest.successValidator(success)
            return try await preparedRequest.transform(success: success)

        } catch let transportFailure as TransportFailure {
            guard let quickRecovered = preparedRequest.quickRecoveryTransformer(transportFailure) else {
                return try await attemptToRecover(from: transportFailure, executing: preparedRequest)
            }

            return try await preparedRequest.transform(success: quickRecovered)
        } catch {
            return try await attemptToRecover(from: error, executing: preparedRequest)
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    public func execute<R>(request: Request<R>, delegate: (any TransportTaskDelegate)?) async throws -> R {
        assert(!(request.method == .get && request.body != nil), "An HTTP GET request should not contain request body data.")

        let preparedRequest = try await prepare(toExecute: request)

        do {
            let success = try await transportService.execute(request: preparedRequest.urlRequest, delegate: delegate)
            try preparedRequest.successValidator(success)
            return try await preparedRequest.transform(success: success)
            
        } catch let transportFailure as TransportFailure {
            guard let quickRecovered = preparedRequest.quickRecoveryTransformer(transportFailure) else {
                return try await attemptToRecover(from: transportFailure, executing: preparedRequest, delegate: delegate)
            }

            return try await preparedRequest.transform(success: quickRecovered)
        } catch {
            return try await attemptToRecover(from: error, executing: preparedRequest, delegate: delegate)
        }
    }
}

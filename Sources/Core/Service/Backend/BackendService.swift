//
//  BackendService.swift
//  Hyperspace
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public class BackendService {
    
    // MARK: - Properties
    public let transportService: Transporting
    public var recoveryStrategies: [RecoveryStrategy]
    
    // MARK: - Initializer
    public init(transportService: Transporting = TransportService(), recoveryStrategies: RecoveryStrategy...) {
        self.transportService = transportService
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

        do {
            let success = try await transportService.execute(request: request.urlRequest)
            try request.successValidator(success)
            return try await request.transform(success: success)

        } catch let transportFailure as TransportFailure {
            guard let quickRecovered = request.recoveryTransformer(transportFailure) else {
                return try await attemptToRecover(from: transportFailure, executing: request)
            }

            return try await request.transform(success: quickRecovered)
        } catch {
            return try await attemptToRecover(from: error, executing: request)
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    public func execute<R>(request: Request<R>, delegate: TransportTaskDelegate?) async throws -> R {
        assert(!(request.method == .get && request.body != nil), "An HTTP GET request should not contain request body data.")

        do {
            let success = try await transportService.execute(request: request.urlRequest, delegate: delegate)
            try request.successValidator(success)
            return try await request.transform(success: success)
            
        } catch let transportFailure as TransportFailure {
            guard let quickRecovered = request.recoveryTransformer(transportFailure) else {
                return try await attemptToRecover(from: transportFailure, executing: request, delegate: delegate)
            }

            return try await request.transform(success: quickRecovered)
        } catch {
            return try await attemptToRecover(from: error, executing: request, delegate: delegate)
        }
    }
}

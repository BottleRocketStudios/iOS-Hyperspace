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

    public func execute<R>(request: Request<R>, delegate: TransportTaskDelegate? = nil) async throws -> R {
        assert(!(request.method == .get && request.body != nil), "An HTTP GET request should not contain request body data.")

        let result = try await transportService.execute(request: request.urlRequest, delegate: delegate)
        switch result {
        case .success(let success): return try request.transform(success: success)
        case .failure(let failure):
            guard let quickRecovered = request.recoveryTransformer(failure) else {
                return try await attemptToRecover(from: failure, executing: request, delegate: delegate)
            }

            return try request.transform(success: quickRecovered)
        }
    }
}

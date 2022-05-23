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
    public init(transportService: Transporting/* = TransportService()*/, recoveryStrategies: RecoveryStrategy...) {
        self.transportService = transportService
        self.recoveryStrategies = recoveryStrategies
    }
}

// MARK: - BackendService + BackendServiceProtocol
extension BackendService: BackendServicing {

    public func execute<R, E>(request: Request<R, E>) async throws -> R where E: TransportFailureRepresentable {
        assert(!(request.method == .get && request.body != nil), "An HTTP GET request should not contain request body data.")

        let result = try await transportService.execute(request: request.urlRequest, delegate: nil)
        switch result {
        case .success(let success):
            return try request.transform(success: success).get()

        case .failure(let failure):
            guard let quickRecovered = request.recoveryTransformer(failure) else {
                return try await attemptToRecover(from: E(transportFailure: failure), executing: request)
            }

            return try request.transform(success: quickRecovered).get()
        }
    }
}

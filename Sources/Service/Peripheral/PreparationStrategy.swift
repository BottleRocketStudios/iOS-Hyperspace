//
//  PreparationStrategy.swift
//  Hyperspace
//
//  Created by Will McGinty on 7/26/23.
//  Copyright © 2023 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public protocol PreparationStrategy {

    /// Handle any just-in-time transformations needed on the request before execution.
    /// - Parameter request: The request that is about to be executed
    /// - Returns: A modified version of the `Request` that will be executed.
    ///
    ///  While this method is both `async` and `throws`, any errors thrown as part of the preparation are not recoverable using any  of the`RecoveryStrategy` attached to the executing `BackendService`.
    func prepare<R>(toExecute request: Request<R>) async throws -> Request<R>
}

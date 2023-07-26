//
//  PreparationStrategy.swift
//  Hyperspace
//
//  Created by Will McGinty on 7/26/23.
//  Copyright © 2023 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public protocol PreparationStrategy {

    /// <#Description#>
    /// - Parameter request: <#request description#>
    /// - Returns: <#description#>
    func prepare<R>(toExecute request: Request<R>) async throws -> Request<R>
}

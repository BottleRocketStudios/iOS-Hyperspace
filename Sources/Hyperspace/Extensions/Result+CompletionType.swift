//
//  Result+CompletionType.swift
//  Hyperspace-iOS
//
//  Created by Pranjal Satija on 1/8/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import FutureKit
import Result

// This enables promise.complete(result).
extension Result: CompletionType {
    public var completion: Completion<Value> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .fail(error)
        }
    }
}

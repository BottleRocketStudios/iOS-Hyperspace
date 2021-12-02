//
//  Result+Extensions.swift
//  Hyperspace-iOS
//
//  Created by Pranjal Satija on 1/8/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

extension Result {

    var value: Success? {
        switch self {
        case .success(let value): return value
        default: return nil
        }
    }

    var error: Failure? {
        switch self {
        case .failure(let error): return error
        default: return nil
        }
    }

    var isSuccess: Bool {
        return value != nil
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
}

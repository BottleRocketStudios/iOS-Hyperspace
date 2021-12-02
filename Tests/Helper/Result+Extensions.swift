//
//  Result+Extensions.swift
//  Hyperspace-iOS
//
//  Created by Pranjal Satija on 1/8/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

extension Result {
    
    var isFailure: Bool {
        switch self {
        case .failure: return true
        default: return false
        }
    }
    
    var isSuccess: Bool {
        return !isFailure
    }
}

//
//  TestDecodingError.swift
//  Hyperspace
//
//  Created by Daniel Larsen on 10/31/21.
//  Copyright © 2021 Bottle Rocket Studios. All rights reserved.
//

import Foundation

enum TestDecodingError: Error, Equatable {

    case keyNotFound
    case invalidValue
}

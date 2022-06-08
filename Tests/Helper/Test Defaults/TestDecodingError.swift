//
//  TestDecodingError.swift
//  Tests
//
//  Copyright © 2021 Bottle Rocket Studios. All rights reserved.
//

import Foundation

enum TestDecodingError: Error, Equatable {
    case keyNotFound
    case invalidValue
}

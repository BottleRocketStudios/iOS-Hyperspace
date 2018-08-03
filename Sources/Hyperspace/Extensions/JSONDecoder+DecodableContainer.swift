//
//  JSONDecoder+DecodableContainer.swift
//  Hyperspace
//
//  Created by Will McGinty on 5/17/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public extension JSONDecoder {
    
    func decode<T, U: DecodableContainer>(_ type: T.Type, from data: Data, with container: U.Type) throws -> T where T == U.ContainedType {
        return try decode(U.self, from: data).element
    }
}

//
//  JSONDecoder+DecodableContainer.swift
//  Hyperspace
//
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public extension JSONDecoder {
    
    func decode<T, C: DecodableContainer>(_ type: T.Type, from data: Data, with container: C.Type) throws -> T where T == C.Contained {
        return try decode(C.self, from: data).element
    }
    
    func decode<T, C: DecodableContainer>(from data: Data, with container: C.Type) throws -> T where T == C.Contained {
        return try decode(T.self, from: data, with: container)
    }
}

public extension JSONEncoder {
    
    func encode<T, C: EncodableContainer>(_ element: T, in container: C.Type) throws -> Data where T == C.Contained {
        return try encode(C(element: element))
    }
}

//
//  JSONDecoder+DecodableContainer.swift
//  Hyperspace
//
//  Created by Will McGinty on 5/17/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public extension JSONDecoder {
    
    func decode<R, C: DecodableContainer>(_ type: R.Type, from data: Data, with container: C.Type) throws -> R where R == C.Contained {
        return try decode(C.self, from: data).element
    }
    
    func decode<R, C: DecodableContainer>(from data: Data, with container: C.Type) throws -> R where R == C.Contained {
        return try decode(R.self, from: data, with: container)
    }
}

public extension JSONEncoder {
    
    func encode<R, C: EncodableContainer>(_ element: R, in container: C.Type) throws -> Data where R == C.Contained {
        return try encode(C(element: element))
    }
}

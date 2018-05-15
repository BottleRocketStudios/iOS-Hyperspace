//
//  AnyDecodable.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 5/14/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation

///A type-erased 'Decodable' value. This type forwards Decoding to the underlying value, allowing the user to decode heterogenous dictionaries successfully using [String: AnyDecodable].
struct AnyDecodable: Decodable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

extension AnyDecodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.init(())
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let uint = try? container.decode(UInt.self) {
            self.init(uint)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let array = try? container.decode([AnyDecodable].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: AnyDecodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyDecodable value could not be decoded")
        }
    }
}

// swiftlint:disable cyclomatic_complexity
extension AnyDecodable: Equatable {
    public static func == (lhs: AnyDecodable, rhs: AnyDecodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (Void, Void): return true
        case let (lhs as Bool, rhs as Bool): return lhs == rhs
        case let (lhs as Int, rhs as Int): return lhs == rhs
        case let (lhs as Int8, rhs as Int8): return lhs == rhs
        case let (lhs as Int16, rhs as Int16): return lhs == rhs
        case let (lhs as Int32, rhs as Int32): return lhs == rhs
        case let (lhs as Int64, rhs as Int64): return lhs == rhs
        case let (lhs as UInt, rhs as UInt): return lhs == rhs
        case let (lhs as UInt8, rhs as UInt8): return lhs == rhs
        case let (lhs as UInt16, rhs as UInt16): return lhs == rhs
        case let (lhs as UInt32, rhs as UInt32): return lhs == rhs
        case let (lhs as UInt64, rhs as UInt64): return lhs == rhs
        case let (lhs as Float, rhs as Float): return lhs == rhs
        case let (lhs as Double, rhs as Double): return lhs == rhs
        case let (lhs as String, rhs as String): return lhs == rhs
        case (let lhs as [String: AnyDecodable], let rhs as [String: AnyDecodable]): return lhs == rhs
        case (let lhs as [AnyDecodable], let rhs as [AnyDecodable]): return lhs == rhs
        default: return false
        }
    }
}
// enable:disable cyclomatic_complexity

// MARK: CustomStringConvertible
extension AnyDecodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case is Void: return String(describing: nil as Any?)
        case let value as CustomStringConvertible: return value.description
        default: return String(describing: value)
        }
    }
}

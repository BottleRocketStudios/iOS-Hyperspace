//
//  FormURLEncoder.swift
//  Hyperspace
//
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import Foundation

struct URLFormEncoder {

    /// Form URL encodes the specified content suitably for attaching to an HTTP request. The only specification for this encoding is in the [Forms][spec]
    /// section of the HTML 4.01 Specification. <http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4>
    /// - Parameter formContent: The `String` content that makes up the form elements
    /// - Returns: A `Data?` object that represents the encoded form
    public func encode(_ formContent: [(String, String)]) -> Data? {
        return formContent.compactMap {
            guard let lhs = formURLEscaped(string: $0), let rhs = formURLEscaped(string: $1) else { return nil }
            return lhs + "=" + rhs
        }
        .joined(separator: "&")
        .data(using: .utf8)
     }
}

// MARK: - Helper
extension URLFormEncoder {

    func formURLEscaped(string: String) -> String? {
        return string.replacingOccurrences(of: "\n", with: "\r\n")
            .addingPercentEncoding(withAllowedCharacters: .urlFormAllowed)?.replacingOccurrences(of: " ", with: "+")
    }
}

// MARK: - URLForm Allowed Character Set
private extension CharacterSet {

    /*
     - The " " will later be converted to a "+"
     - https://url.spec.whatwg.org/#urlencoded-serializing
     */
    static let urlFormAllowed: CharacterSet = {
        CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-._* ")
    }()
}

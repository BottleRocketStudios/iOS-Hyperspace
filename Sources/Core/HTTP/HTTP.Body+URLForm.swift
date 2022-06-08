//
//  HTTP.Body+URLForm.swift
//  Hyperspace
//
//  Created by Will McGinty on 5/26/22.
//  Copyright © 2022 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public extension HTTP.Body {
    
    /// Initializes a new `HTTP.Body` instance given a set of URL form content
    /// - Parameters:
    ///   - formContent: An array of `(String, String)` representing the content to be encoded.
    ///   - additionalHeaders: Any additional HTTP headers that should be sent with the request.
    /// - Returns: A new instance of `HTTP.Body` with the given form content.
    static func urlForm(using formContent: [(String, String)], additionalHeaders: [HTTP.HeaderKey: HTTP.HeaderValue] = [.contentType: .applicationFormURLEncoded]) -> Self {
        let formURLEncoder = URLFormEncoder()
        return .init(formURLEncoder.encode(formContent), additionalHeaders: additionalHeaders)
    }
}

// MARK: - URLFormEncoder
struct URLFormEncoder {

    /// Form URL encodes the specified content suitably for attaching to an HTTP request. The only specification for this encoding is in the [Forms][spec]
    /// section of the HTML 4.01 Specification. <http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4>
    /// - Parameter formContent: The `String` content that makes up the form elements
    /// - Returns: A `Data?` object that represents the encoded form
    func encode(_ formContent: [(String, String)]) -> Data? {
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

// MARK: - URL Form Allowed Character Set
private extension CharacterSet {

    /*
     - The " " will later be converted to a "+"
     - https://url.spec.whatwg.org/#urlencoded-serializing
     */
    static let urlFormAllowed: CharacterSet = {
        CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-._* ")
    }()
}

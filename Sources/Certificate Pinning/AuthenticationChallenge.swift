//
//  AuthenticationChallenge.swift
//  Hyperspace
//
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// This protocol represents a generic authentication challenge, such as those presented as part of the SSL and TLS handshakes.
public protocol AuthenticationChallenge {
    
    /// The host of the remote connection.
    var host: String { get }
    
    /// The method of authentication. For possible values see `URLAuthenticationChallenge`.
    var authenticationMethod: String { get }
    
    /// The `SecTrust` object packaged as part of the challenge. Will be nil unless the challenge is a server trust challenge.
    var serverTrust: SecTrust? { get }
}

public extension AuthenticationChallenge {
    
    var isServerTrustAuthentication: Bool {
        return authenticationMethod == NSURLAuthenticationMethodServerTrust
    }
}

// MARK: - URLAuthenticationChallenge conformance to AuthenticationChallenge

extension URLAuthenticationChallenge: AuthenticationChallenge {
    public var host: String { return protectionSpace.host }
    public var authenticationMethod: String { return protectionSpace.authenticationMethod }
    public var serverTrust: SecTrust? { return protectionSpace.serverTrust }
}

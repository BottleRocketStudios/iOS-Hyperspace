//
//  AuthenticationChallenge.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 1/31/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public protocol AuthenticationChallenge {
    var host: String { get }
    var authenticationMethod: String { get }
    var serverTrust: SecTrust? { get }
}

// MARK: URLAuthenticationChallenge Conformance
extension URLAuthenticationChallenge: AuthenticationChallenge {
    public var host: String { return protectionSpace.host }
    public var authenticationMethod: String { return protectionSpace.authenticationMethod }
    public var serverTrust: SecTrust? { return protectionSpace.serverTrust }
}

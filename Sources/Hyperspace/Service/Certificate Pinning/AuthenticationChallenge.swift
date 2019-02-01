//
//  AuthenticationChallenge.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 1/31/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// <#Description#>
public protocol AuthenticationChallenge {
    
    /// <#Description#>
    var host: String { get }
    
    /// <#Description#>
    var authenticationMethod: String { get }
    
    /// <#Description#>
    var serverTrust: SecTrust? { get }
}

// MARK: - URLAuthenticationChallenge conformance to AuthenticationChallenge

extension URLAuthenticationChallenge: AuthenticationChallenge {
    public var host: String { return protectionSpace.host }
    public var authenticationMethod: String { return protectionSpace.authenticationMethod }
    public var serverTrust: SecTrust? { return protectionSpace.serverTrust }
}

//
//  PinningConfiguration.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 1/30/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public struct PinningConfiguration {
    
    public struct DomainConfiguration: Hashable {
        let domain: String //ex: www.apple.com
        let enforced: Bool //BLOCk if fail, otherwise proceed
        let includeSubdomains: Bool // x.apple.com is part of apple.com
        
        public init(domain: String, enforced: Bool = false, includeSubdomains: Bool = true) {
            self.domain = domain
            self.enforced = enforced
            self.includeSubdomains = includeSubdomains
        }
    }
    
    // MARK: Properties
    public let domainConfigurations: Set<DomainConfiguration>
    
    // MARK: Initializers
    public init(domainConfigurations: [DomainConfiguration]) {
        self.domainConfigurations = Set(domainConfigurations)
    }
    
    // MARK: Interface
    func shouldValidateAuthenticationChallenge(fromHost host: String) -> Bool {
        return domainConfigurations.map { $0.domain }.contains(host)
    }
    
    func authenticationDispositionForFailedValidation(forHost host: String) -> URLSession.AuthChallengeDisposition {
        guard let domainConfig = domainConfiguration(forHost: host) else { return .performDefaultHandling }
        return domainConfig.enforced ? .cancelAuthenticationChallenge : .performDefaultHandling
    }
}

// MARK: Helper
private extension PinningConfiguration {
    
    func domainConfiguration(forHost host: String) -> DomainConfiguration? {
        return domainConfigurations.first { $0.domain == host }
    }
}

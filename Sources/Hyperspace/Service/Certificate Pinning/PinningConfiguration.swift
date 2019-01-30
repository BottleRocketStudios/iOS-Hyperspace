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
        
        // MARK: Properties
        let domain: String //ex: www.apple.com
        let enforced: Bool //BLOCk if fail, otherwise proceed
        let includeSubdomains: Bool // x.apple.com is part of apple.com
        let certificate: Data
        let expiration: Date?
        
        // MARK: Initializers
        public init(domain: String, enforced: Bool = false, includeSubdomains: Bool = true, certificate: Data, expiration: Date? = nil) {
            self.domain = domain
            self.enforced = enforced
            self.includeSubdomains = includeSubdomains
            self.certificate = certificate
            self.expiration = expiration
        }
        
        // MARK: Interface
        func shouldValidateCertificate(forHost host: String, at date: Date) -> Bool {
            guard let expired = expiration else { return true }
            return date < expired
        }
        
        func authenticationDispositionForFailedValidation(forHost host: String) -> URLSession.AuthChallengeDisposition {
            if enforced {
                return .cancelAuthenticationChallenge
            }
            
            debugPrint("SSL certificate pin failed for host: '\(host)'. Configuration set to allow connection anyway.")
            return .performDefaultHandling
        }
    }
    
    // MARK: Properties
    public let domainConfigurations: Set<DomainConfiguration>
    
    // MARK: Initializers
    public init(domainConfigurations: [DomainConfiguration]) {
        self.domainConfigurations = Set(domainConfigurations)
    }
    
    // MARK: Interface
    func domainConfiguration(forHost host: String) -> DomainConfiguration? {
        return domainConfigurations.first { $0.domain == host }
    }
    
    func shouldValidateCertificate(forHost host: String, at date: Date) -> Bool {
        return domainConfiguration(forHost: host).map { $0.shouldValidateCertificate(forHost: host, at: date) } ?? false
    }
    
    func authenticationDispositionForFailedValidation(forHost host: String) -> URLSession.AuthChallengeDisposition {
        return domainConfiguration(forHost: host).map { $0.authenticationDispositionForFailedValidation(forHost: host) } ?? .performDefaultHandling
    }
}

// MARK: Helper
extension PinningConfiguration {
}

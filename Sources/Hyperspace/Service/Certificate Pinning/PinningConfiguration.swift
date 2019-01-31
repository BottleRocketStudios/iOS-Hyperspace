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
        let certificates: [Data]
        let expiration: Date?
        
        // MARK: Initializers
        public init(domain: String, enforced: Bool = false, includeSubdomains: Bool = true, certificateHashes: [String], expiration: Date? = nil) {
            let certificates = certificateHashes.compactMap { Data(base64Encoded: $0, options: []) }
            self.init(domain: domain, enforced: enforced, includeSubdomains: includeSubdomains, certificates: certificates, expiration: expiration)
        }
        
        public init(domain: String, enforced: Bool = false, includeSubdomains: Bool = true, certificates: [Data], expiration: Date? = nil) {
            self.domain = domain
            self.enforced = enforced
            self.includeSubdomains = includeSubdomains
            self.certificates = certificates
            self.expiration = expiration
        }
        
        // MARK: Interface
        func shouldValidateCertificate(forHost host: String) -> Bool {
            guard includeSubdomains else { return domain == host }
            return host.contains(domain)
        }
        
        func shouldValidateCertificate(forHost host: String, at date: Date) -> Bool {
            guard shouldValidateCertificate(forHost: host), let expired = expiration else { return true }
            return date < expired
        }
        
        func validate(against remoteCertificate: Data) -> Bool {
            return certificates.contains(remoteCertificate)
        }
        
        var dispositionForFailedValidation: URLSession.AuthChallengeDisposition {
            if enforced {
                return .cancelAuthenticationChallenge
            }
            
            debugPrint("SSL certificate pin failed for host: '\(domain)'. Configuration set to allow connection anyway.")
            return .performDefaultHandling
        }
        
        // MARK: Hashable
        public var hashValue: Int {
            return domain.hashValue
        }
        
        public static func == (lhs: DomainConfiguration, rhs: DomainConfiguration) -> Bool {
            return lhs.domain == rhs.domain
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
        return domainConfigurations.first { $0.shouldValidateCertificate(forHost: host) }
    }
    
    func shouldValidateCertificate(forHost host: String, at date: Date) -> Bool {
        return domainConfiguration(forHost: host).map { $0.shouldValidateCertificate(forHost: host, at: date) } ?? false
    }
    
    func authenticationDispositionForFailedValidation(forHost host: String) -> URLSession.AuthChallengeDisposition {
        return domainConfiguration(forHost: host).map { $0.dispositionForFailedValidation } ?? .performDefaultHandling
    }
}

// MARK: Helper
extension PinningConfiguration {
}

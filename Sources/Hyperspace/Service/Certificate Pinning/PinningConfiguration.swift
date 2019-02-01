//
//  PinningConfiguration.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 1/30/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

@available(iOSApplicationExtension 10.0, *)
@available(watchOSApplicationExtension 3.0, *)
public struct PinningConfiguration {
    
    public struct DomainConfiguration: Hashable {
        
        // MARK: Properties
    
        /// The URL domain for which this configuration is responsible
        let domain: String
        
        /// Determines whether any failures to pin (`.block` as a `ValidationDecision`) will cause the connection to be blocked. Setting this value to 'false' will allow connections that fail pinning validation. Defaults to `true`.
        let enforced: Bool
        
        /// Any subdomains of the configuration's domain should be included. For example, dev.apple.com would be included for a configuration for apple.com. Defaults to `true`.
        let includeSubdomains: Bool
        
        /// The public key hashes for which to match the presented remote certificate.
        let pinningHashes: [Data]
        
        /// The date of expiration for the certificate in question. For any dates after the expiration, pinning will not be attempted, and the connection allowed.
        let expiration: Date?
        
        // MARK: Initializers
        
        /// Creates an instance of `DomainConfiguration` which will govern how any presented SSL certificate from that domain will be pinned.
        ///
        /// - Parameters:
        ///   - domain: The domain for which this configuration is responsible.
        ///   - enforced: When this value is set to true, a failure to pin a request will cause the connection to be blocked. Defaults to true.
        ///   - includeSubdomains: Include any subdomains of the given domain in the pinning process. Defaults to true.
        ///   - certificates: An array of `SectCertificate`. These certificates will have their public key extracted and hashed. This hash will then be compared against the presented remote SSL certificate at authentication time.
        ///   - expiration: The expiration date of the SSL Certificate to be pinned. After this date, pinning will not be attempted.
        /// - Throws: A CertificateHasher.Error if the given `SecCertificate` can not be properly hashed.
        public init(domain: String, enforced: Bool = true, includeSubdomains: Bool = true, certificates: [SecCertificate], expiration: Date? = nil) throws {
            let pinningHashes = try certificates.compactMap { try CertificateHasher.pinningHash(for: $0) }
            self.init(domain: domain, enforced: enforced, includeSubdomains: includeSubdomains, pinningHashes: pinningHashes, expiration: expiration)
        }
        
        /// Creates an instance of `DomainConfiguration` which will govern how any presented SSL certificate from that domain will be pinned.
        ///
        /// - Parameters:
        ///   - domain: The domain for which this configuration is responsible.
        ///   - enforced: When this value is set to true, a failure to pin a request will cause the connection to be blocked. Defaults to true.
        ///   - includeSubdomains: Include any subdomains of the given domain in the pinning process. Defaults to true.
        ///   - encodedPinningHashes: An array of base-64 encoded strings representing the hash of a certificate's public key.
        ///   - expiration: The expiration date of the SSL Certificate to be pinned. After this date, pinning will not be attempted.
        public init(domain: String, enforced: Bool = true, includeSubdomains: Bool = true, encodedPinningHashes: [String], expiration: Date? = nil) {
            let pinningHashes = encodedPinningHashes.compactMap { Data(base64Encoded: $0) }
            self.init(domain: domain, enforced: enforced, includeSubdomains: includeSubdomains, pinningHashes: pinningHashes, expiration: expiration)
        }
        
        /// Creates an instance of `DomainConfiguration` which will govern how any presented SSL certificate from that domain will be pinned.
        ///
        /// - Parameters:
        ///   - domain: The domain for which this configuration is responsible.
        ///   - enforced: When this value is set to true, a failure to pin a request will cause the connection to be blocked. Defaults to true.
        ///   - includeSubdomains: Include any subdomains of the given domain in the pinning process. Defaults to true.
        ///   - pinningHashes: An array of public key hashes that will be used to verify the presented SSL certificate.
        ///   - expiration: The expiration date of the SSL Certificate to be pinned. After this date, pinning will not be attempted.
        init(domain: String, enforced: Bool = true, includeSubdomains: Bool = true, pinningHashes: [Data], expiration: Date? = nil) {
            self.domain = domain
            self.enforced = enforced
            self.includeSubdomains = includeSubdomains
            self.pinningHashes = pinningHashes
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
        
        func validate(against remoteCertificate: SecCertificate) -> Bool {
            let pinningHash = try? CertificateHasher.pinningHash(for: remoteCertificate)
            return pinningHash.map(pinningHashes.contains) ?? false
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
    
    /// A list of `DomainConfiguration` objects which each represent a single domain's SSL pinning configuration.
    public let domainConfigurations: Set<DomainConfiguration>
    
    // MARK: Initializers
    
    /// Create a `PinningConfiguration` instance which will govern how the validator behaves when presented with a remote SSL certificate.
    ///
    /// - Parameter domainConfigurations: A list of `DomainConfiguration` objects which control the pinning process for each individual domain.
    ///         Note that providing multiple configurations for a single domain will result in only the first being kept, the rest discarded.
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

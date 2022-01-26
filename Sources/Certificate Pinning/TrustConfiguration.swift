//
//  TrustConfiguration.swift
//  Hyperspace
//
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/** A configuration object which controls how a `TrustValidator` object makes decisions on which connections to accept and which to block. The configuration
    object consists of a series of configuration objects, each designed for a single domain. */
@available(iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *)
public struct TrustConfiguration {
    
    /// The `CertificateExpirationPolicy` determines how the validation should proceed when the certificate being pinned has expired.
    ///
    /// - allow: Connections should be allowed after the certificate has expired, on the given `Date`.
    /// - block: Connections should be blocked after the certificate has expired.
    public enum CertificateExpirationPolicy: Hashable {
        case allow(after: Date)
        case block
        
        var expiration: Date? {
            switch self {
            case .allow(after: let date): return date
            case .block: return nil
            }
        }
    }
    
    /// A configuration object which controls how a `TrustValidator` object makes decisions on which connections to accept and which to block, and pertains only to a single domain.
    public struct DomainConfiguration: Hashable {
        
        // MARK: - Properties
    
        /// The URL domain for which this configuration is responsible. Should be entered in the format `example.com`.
        let domain: String
        
        /// Determines whether any failures to pin (`.block` as a `ValidationDecision`) will cause the connection to be blocked. Setting this value to 'false' will allow connections that fail pinning validation. Defaults to `true`.
        let enforced: Bool
        
        /// Any subdomains of the configuration's domain should be included. For example, dev.apple.com would be included for a configuration for apple.com. Defaults to `true`.
        let includeSubdomains: Bool
        
        /// The public key hashes for which to match the presented remote certificate.
        let pinningHashes: [Data]
        
        /// The expiration policy for the pinned certificate. See `CertificateExpirationPolicy`.
        let expirationPolicy: CertificateExpirationPolicy
        
        // MARK: - Initializers
        
        /// Creates an instance of `DomainConfiguration` which will govern how any presented SSL certificate from that domain will be pinned.
        ///
        /// - Parameters:
        ///   - domain: The domain for which this configuration is responsible. Should be entered in the format `example.com`.
        ///   - enforced: When this value is set to true, a failure to pin a request will cause the connection to be blocked. Defaults to true.
        ///   - includeSubdomains: Include any subdomains of the given domain in the pinning process. Defaults to true.
        ///   - certificates: An array of `SecCertificate`. These certificates will have their public key extracted and hashed. This hash will then be compared against the presented remote SSL certificate at authentication time.
        ///   - expirationPolicy: The expiration policy to be used when creating this domain. A value of `.block` will cause an expired certificate to block all connections.
        /// - Throws: A CertificateHasher.Error if the given `SecCertificate` can not be properly hashed.
        public init(domain: String, enforced: Bool = true, includeSubdomains: Bool = true, certificates: [SecCertificate], expirationPolicy: CertificateExpirationPolicy = .block) throws {
            let pinningHashes = try certificates.compactMap { try CertificateHasher.pinningHash(for: $0) }
            self.init(domain: domain, enforced: enforced, includeSubdomains: includeSubdomains, pinningHashes: pinningHashes, expirationPolicy: expirationPolicy)
        }
        
        /// Creates an instance of `DomainConfiguration` which will govern how any presented SSL certificate from that domain will be pinned.
        ///
        /// - Parameters:
        ///   - domain: The domain for which this configuration is responsible. Should be entered in the format `example.com`.
        ///   - enforced: When this value is set to true, a failure to pin a request will cause the connection to be blocked. Defaults to true.
        ///   - includeSubdomains: Include any subdomains of the given domain in the pinning process. Defaults to true.
        ///   - encodedPinningHashes: An array of base-64 encoded strings representing the hash of a certificate's public key.
        ///   - expirationPolicy: The expiration policy to be used when creating this domain. A value of `.block` will cause an expired certificate to block all connections.
        public init(domain: String, enforced: Bool = true, includeSubdomains: Bool = true, encodedPinningHashes: [String], expirationPolicy: CertificateExpirationPolicy = .block) {
            let pinningHashes = encodedPinningHashes.compactMap { Data(base64Encoded: $0) }
            self.init(domain: domain, enforced: enforced, includeSubdomains: includeSubdomains, pinningHashes: pinningHashes, expirationPolicy: expirationPolicy)
        }
        
        /// Creates an instance of `DomainConfiguration` which will govern how any presented SSL certificate from that domain will be pinned.
        ///
        /// - Parameters:
        ///   - domain: The domain for which this configuration is responsible. Should be entered in the format `example.com`.
        ///   - enforced: When this value is set to true, a failure to pin a request will cause the connection to be blocked. Defaults to true.
        ///   - includeSubdomains: Include any subdomains of the given domain in the pinning process. Defaults to true.
        ///   - pinningHashes: An array of public key hashes that will be used to verify the presented SSL certificate.
        ///   - expirationPolicy: The expiration policy to be used when creating this domain. A value of `.block` will cause an expired certificate to block all connections.
        public init(domain: String, enforced: Bool = true, includeSubdomains: Bool = true, pinningHashes: [Data], expirationPolicy: CertificateExpirationPolicy = .block) {
            self.domain = domain
            self.enforced = enforced
            self.includeSubdomains = includeSubdomains
            self.pinningHashes = pinningHashes
            self.expirationPolicy = expirationPolicy
        }
        
        // MARK: - Interface
        
        func shouldValidateCertificate(forHost host: String) -> Bool {
            guard includeSubdomains else { return domain == host }
            return host.contains(domain)
        }
        
        func shouldValidateCertificate(forHost host: String, at date: Date) -> Bool {
            guard shouldValidateCertificate(forHost: host), let expired = expirationPolicy.expiration else { return true }
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
    }
    
    // MARK: - Properties
    
    /// A list of `DomainConfiguration` objects which each represent a single domain's SSL pinning configuration.
    public let domainConfigurations: [DomainConfiguration]
    
    // MARK: - Initializers
    
    /// Create a `TrustConfiguration` instance which will govern how the validator behaves when presented with a remote SSL certificate.
    ///
    /// - Parameter domainConfigurations: A list of `DomainConfiguration` objects which control the pinning process for each individual domain.
    ///         There must only be a single domain configuration for a given domain. Multiple domain configurations will trigger an assertion.
    public init(domainConfigurations: [DomainConfiguration]) {
        assert(Set(domainConfigurations.map { $0.domain }).count == domainConfigurations.count, "You must not provide multiple domain configurations for any given domain.")
        self.domainConfigurations = domainConfigurations
    }
    
    // MARK: - Interface
    
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

// MARK: - TrustConfiguration conformance to ExpressibleByArrayLiteral

@available(iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *)
extension TrustConfiguration: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = DomainConfiguration
    
    public init(arrayLiteral elements: TrustConfiguration.DomainConfiguration...) {
        self.init(domainConfigurations: elements)
    }
}

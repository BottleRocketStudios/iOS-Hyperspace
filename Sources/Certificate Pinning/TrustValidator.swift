//
//  TrustValidator.swift
//  Hyperspace
//
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/** This class performs validation on authentication challenges presented to it. In addition to ensuring that the challenge is trusted by the operating system, it will
    ensure that the certificate being presented as part of the SSL/TLS authentication challenge is recognized by the device. */
@available(iOS, deprecated: 14.0, message: "Prefer the `NSPinnedDomains` Info.plist key")
@available(macOS, deprecated: 11.0, message: "Prefer the `NSPinnedDomains` Info.plist key")
public class TrustValidator {
    
    // MARK: - ValidationDecision Subtype
    
    public enum Decision {
        case allow(URLCredential) /// The certificate has passed validation, and the authentication challenge should be allowed with the given credentials
        case block /// The certificate has not passed pinning validation, the authentication challenge should be blocked
        case notPinned /// The request domain has not been configured to be pinned
    }
    
    // MARK: - Properties
    
    public let configuration: TrustConfiguration
    
    // MARK: - Initializers
    
    public init(configuration: TrustConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: Interface
    
    /// Determines if the validator can handle a given `AuthenticationChallenge`.
    ///
    /// - Parameter challenge: The `URLAuthenticationChallenge` presented to the `URLSession` object with which this validator is associated.
    /// - Returns: Returns `true` when the 'server trust' authentication challenge has been handled. Returns `false` for all other types of authentication challenge.
    public func canHandle(challenge: AuthenticationChallenge) -> Bool {
        return challenge.isServerTrustAuthentication && challenge.serverTrust != nil
    }
    
    /// Allows the `TrustValidator` the chance to validate a given `URLAuthenticationChallenge` against its local certificate.
    ///
    /// - Parameters:
    ///   - challenge: The `URLAuthenticationChallenge` presented to the `URLSession` object with which this validator is associated.
    ///   - handler: The handler to be called when the challenge is a 'server trust' authentication challenge. For all other types of authentication challenge, this handler will NOT be called.
    public func handle(challenge: AuthenticationChallenge, handler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard canHandle(challenge: challenge), let serverTrust = challenge.serverTrust else {
            return // The challenge was not a server trust evaluation, and so left unhandled
        }
        
        switch evaluate(serverTrust, forHost: challenge.host) {
        case .allow(let credential): handler(.useCredential, credential)
        case .block: handler(configuration.authenticationDispositionForFailedValidation(forHost: challenge.host), nil)
        case .notPinned: handler(.performDefaultHandling, nil)
        }
    }
    
    func evaluate(_ trust: SecTrust, forHost host: String, date: Date = Date()) -> Decision {
        guard let domainConfig = configuration.domainConfiguration(forHost: host), domainConfig.shouldValidateCertificate(forHost: host, at: date) else {
            return .notPinned // We are either not able to retrieve the certificate from the trust or we are not configured to pin this domain
        }
        
        // Set an SSL policy and evaluate the trust
        let policies = NSArray(array: [SecPolicyCreateSSL(true, nil)])
        SecTrustSetPolicies(trust, policies)
        
        guard trust.isValid else { return .block }
        
        // If the server trust evaluation is successful, walk the certificate chain
        let certificateCount = SecTrustGetCertificateCount(trust)
        for certIndex in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(trust, certIndex) else { continue }
            
            if domainConfig.validate(against: certificate) {
                // Found a pinned certificate, allow the connection
                return .allow(URLCredential(trust: trust))
            }
        }
        
        return .block
    }
}

// MARK: - SecTrust Utility
@available(iOS, deprecated: 14.0, message: "Prefer the `NSPinnedDomains` Info.plist key")
@available(macOS, deprecated: 11.0, message: "Prefer the `NSPinnedDomains` Info.plist key")
extension SecTrust {
    
    /// Evaluates `self` and returns `true` if the evaluation succeeds with a value of `.unspecified` or `.proceed`.
    var isValid: Bool {
        return CertificateHasher.checkValidity(of: self)
    }
}

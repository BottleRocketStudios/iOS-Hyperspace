//
//  CertificateValidator.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 1/30/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public class CertificateValidator {
    
    // MARK: ValidationDecision Subtype
    public enum ValidationDecision {
        case allow(URLCredential)
        case block
        case notPinned
    }
    
    // MARK: Properties
    public let configuration: PinningConfiguration
    
    // MARK: Initializers
    public init(configuration: PinningConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: Interface
    
    /// Allows the `CertificateValidator` the chance to validate a given `URLAuthenticationChallenge` against it's local certificate.
    ///
    /// - Parameters:
    ///   - challenge: The `URLAuthenticationChallenge` presented to the `URLSession` object with which this validator is associated.
    ///   - handler: The handler to be called when the challenge is a 'server trust' authentication challenge. For all other types of authentication challenge, this handler will NOT be called.
    public func handle(challenge: URLAuthenticationChallenge, handler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Bool {
        let host = challenge.protectionSpace.host
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let serverTrust = challenge.protectionSpace.serverTrust else {
            return false //The challenge was not a server trust evaluation, and so left unhandled
        }
        
        switch evaluate(serverTrust, forHost: host) {
        case .allow(let credential): handler(.useCredential, credential)
        case .block:
            let finalDisposition = configuration.authenticationDispositionForFailedValidation(forHost: host)
            handler(finalDisposition, nil)
        case .notPinned: handler(.performDefaultHandling, nil)
        }
        
        return true
    }
    
    public func evaluate(_ trust: SecTrust, forHost host: String) -> ValidationDecision {
        guard let domainConfig = configuration.domainConfiguration(forHost: host), domainConfig.shouldValidateCertificate(forHost: host, at: Date()), let certificate = SecTrustGetCertificateAtIndex(trust, 0) else {
            return .notPinned //We are either not able to retrieve the certificate from the trust or we are not configured to pin this domain
        }
        
        let policies = NSArray(array: [SecPolicyCreateSSL(true, (host as CFString))])
        SecTrustSetPolicies(trust, policies)
        
        var result: SecTrustResultType = .unspecified
        SecTrustEvaluate(trust, &result)
        
        let remoteCertificate = SecCertificateCopyData(certificate) as Data
        if ((result == .proceed) || (result == .unspecified)) && remoteCertificate == domainConfig.certificate {
            return .allow(URLCredential(trust: trust))
        } else {
            return .block
        }
    }
}

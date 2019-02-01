//
//  CertificateValidator.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 1/30/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

@available(iOSApplicationExtension 10.0, *)
public class CertificateValidator {
    
    // MARK: ValidationDecision Subtype
    public enum ValidationDecision {

        case allow(URLCredential) /// The certificate has passed validation, and the authentication challge should be allowed with the given credentials
        case block /// The certificate has not passed pinning validation, the authentication challenge should be blocked
        case notPinned /// The request domain has not been configured to be pinned
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
    
    public func evaluate(_ trust: SecTrust, forHost host: String, date: Date = Date()) -> ValidationDecision {
        guard let domainConfig = configuration.domainConfiguration(forHost: host), domainConfig.shouldValidateCertificate(forHost: host, at: date) else {
            return .notPinned //We are either not able to retrieve the certificate from the trust or we are not configured to pin this domain
        }
        
        //Set an SSL policy and evaluate the trust
        let policies = NSArray(array: [SecPolicyCreateSSL(true, (host as CFString))])
        SecTrustSetPolicies(trust, policies)
        
        var result: SecTrustResultType = .unspecified
        SecTrustEvaluate(trust, &result)
        
        if result == .proceed || result == .unspecified {
            
            //If the server trust evaluation is successful, walk the certificate chain
            let certificateCount = SecTrustGetCertificateCount(trust)
            for certIndex in 0..<certificateCount {
                guard let certificate = SecTrustGetCertificateAtIndex(trust, certIndex) else { continue }
                
                if domainConfig.validate(against: certificate) {
                    //Found a pinned certificate, allow the connection
                    return .allow(URLCredential(trust: trust))
                }
            }
        }
        
        return .block
    }
}

//
//  CertificateValidator.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 1/30/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

public class CertificateValidator {
    
    // MARK: Properties
    public let localCertificate: Data
    
    // MARK: Initializers
    public init(localCertificate: Data) {
        self.localCertificate = localCertificate
    }
    
    // MARK: Interface
    public func handle(challenge: URLAuthenticationChallenge, handler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let serverTrust = challenge.protectionSpace.serverTrust else {
            return //The challenge was not a server trust evaluation, and so left unhandled
        }
        
        switch evaluate(serverTrust, forHost: challenge.protectionSpace.host, againstLocalCertificate: localCertificate) {
        case .allow(let credential): handler(.useCredential, credential)
        case .block: handler(.cancelAuthenticationChallenge, nil)
        case .notPinned: handler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        }
    }
}

// MARK: Helper
private extension CertificateValidator {
    
    enum ValidationDecision {
        case allow(URLCredential)
        case block
        case notPinned
    }
    
    func evaluate(_ trust: SecTrust, forHost host: String, againstLocalCertificate localCert: Data) -> ValidationDecision {
        guard let certificate = SecTrustGetCertificateAtIndex(trust, 0) else {
            return .notPinned //We are not able to continue to validate the certificate if it we can't obtain it from the trust
        }
        
        let policies = NSArray(array: [SecPolicyCreateSSL(true, (host as CFString))])
        SecTrustSetPolicies(trust, policies)
        
        var result: SecTrustResultType = .unspecified
        SecTrustEvaluate(trust, &result)
        
        let remoteCertificate = SecCertificateCopyData(certificate) as Data
        if ((result == .proceed) || (result == .unspecified)) && remoteCertificate == localCert {
            return .allow(URLCredential(trust: trust))
        } else {
            return .block
        }
    }
}

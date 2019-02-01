//
//  PinningTests.swift
//  Hyperspace
//
//  Created by Will McGinty on 1/30/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class PinningTests: XCTestCase {
    
    struct TestAuthenticationChallenge: AuthenticationChallenge {
        let host: String
        let authenticationMethod: String
        let serverTrust: SecTrust?
        
        init(host: String, authenticationMethod: String = NSURLAuthenticationMethodServerTrust, serverTrust: SecTrust?) {
            self.host = host
            self.authenticationMethod = authenticationMethod
            self.serverTrust = serverTrust
        }
    }
    
    private let defaultHost = "apple.com"
    private let secondaryHost = "google.com"
    
    func test_DomainConfiguration_detectsSubdomains() {
        let config = TrustConfiguration.DomainConfiguration(domain: defaultHost, pinningHashes: [Data()])
        XCTAssertTrue(config.shouldValidateCertificate(forHost: defaultHost))
        XCTAssertTrue(config.shouldValidateCertificate(forHost: "dev.\(defaultHost)"))
        XCTAssertTrue(config.shouldValidateCertificate(forHost: "x.y.\(defaultHost)"))

        let config2 = TrustConfiguration.DomainConfiguration(domain: defaultHost, includeSubdomains: false, pinningHashes: [Data()])
        XCTAssertFalse(config2.shouldValidateCertificate(forHost: "dev.\(defaultHost)"))
        XCTAssertFalse(config2.shouldValidateCertificate(forHost: "x.y.\(defaultHost)"))
    }

    func test_DomainConfiguration_enforcesOnlyOwnDomain() {
        let config = TrustConfiguration.DomainConfiguration(domain: defaultHost, pinningHashes: [Data()])
        XCTAssertTrue(config.shouldValidateCertificate(forHost: defaultHost))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: ""))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: "google.com"))
    }

    func test_DomainConfiguration_enforcesOnlyBeforeExpiration() {
        let nonExpiringConfig = TrustConfiguration.DomainConfiguration(domain: defaultHost, pinningHashes: [Data()])
        XCTAssertTrue(nonExpiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date()))
        XCTAssertTrue(nonExpiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(1000)))
        XCTAssertTrue(nonExpiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(1000000)))

        let expiration = Date().addingTimeInterval(100)
        let expiringConfig = TrustConfiguration.DomainConfiguration(domain: defaultHost, pinningHashes: [Data()], expiration: expiration)
        XCTAssertTrue(expiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date()))
        XCTAssertTrue(expiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(99)))
        XCTAssertFalse(expiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(1001)))
    }

    func test_DomainConfiguration_finalDispositionForFailedValidation() {
        let enforcedConfig = TrustConfiguration.DomainConfiguration(domain: defaultHost, enforced: true, pinningHashes: [Data()])
        XCTAssertEqual(enforcedConfig.dispositionForFailedValidation, .cancelAuthenticationChallenge)

        let unenforcedConfig = TrustConfiguration.DomainConfiguration(domain: defaultHost, enforced: false, pinningHashes: [Data()])
        XCTAssertEqual(unenforcedConfig.dispositionForFailedValidation, .performDefaultHandling)
    }

    func test_TrustConfiguration_findsCorrectDomainConfiguration() {
        let config = TrustConfiguration(domainConfigurations: [.init(domain: defaultHost, pinningHashes: [Data()]),
                                                                 .init(domain: secondaryHost, pinningHashes: [Data(bytes: [1, 2, 3, 4])])])

        XCTAssertEqual(config.domainConfiguration(forHost: defaultHost)?.domain, defaultHost)
        XCTAssertEqual(config.domainConfiguration(forHost: defaultHost)?.pinningHashes.count, 1)
        XCTAssertEqual(config.domainConfiguration(forHost: defaultHost)?.pinningHashes.first, Data())
        
        XCTAssertEqual(config.domainConfiguration(forHost: secondaryHost)?.domain, secondaryHost)
        XCTAssertEqual(config.domainConfiguration(forHost: secondaryHost)?.pinningHashes.count, 1)
        XCTAssertEqual(config.domainConfiguration(forHost: secondaryHost)?.pinningHashes.first, Data(bytes: [1, 2, 3, 4]))

        XCTAssertNil(config.domainConfiguration(forHost: "bbc.com"))
    }

    func test_TrustConfiguration_finalDispositionForFailedValidation() {
        let domainConfig = TrustConfiguration.DomainConfiguration(domain: defaultHost, enforced: true, pinningHashes: [Data()])
        let config: TrustConfiguration = [domainConfig]

        XCTAssertEqual(config.authenticationDispositionForFailedValidation(forHost: defaultHost), .cancelAuthenticationChallenge)
        XCTAssertEqual(config.authenticationDispositionForFailedValidation(forHost: secondaryHost), .performDefaultHandling)

        let domainConfig2 = TrustConfiguration.DomainConfiguration(domain: defaultHost, enforced: false, pinningHashes: [Data()])
        let config2 = TrustConfiguration(domainConfigurations: [domainConfig2])

        XCTAssertEqual(config2.authenticationDispositionForFailedValidation(forHost: defaultHost), .performDefaultHandling)
    }

    func test_TrustConfiguration_enforcesOnlyBeforeExpiration() {
        let expiration = Date().addingTimeInterval(100)
        let domainConfig = TrustConfiguration.DomainConfiguration(domain: defaultHost, enforced: true, pinningHashes: [Data()], expiration: expiration)
        let config = TrustConfiguration(domainConfigurations: [domainConfig])

        XCTAssertTrue(config.shouldValidateCertificate(forHost: defaultHost, at: Date()))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: defaultHost, at: expiration.addingTimeInterval(1)))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: secondaryHost, at: expiration.addingTimeInterval(1)))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: secondaryHost, at: Date()))

        let domainConfig2 = TrustConfiguration.DomainConfiguration(domain: defaultHost, enforced: true, pinningHashes: [Data()])
        let config2 = TrustConfiguration(domainConfigurations: [domainConfig2])

        XCTAssertTrue(config2.shouldValidateCertificate(forHost: defaultHost, at: Date()))
        XCTAssertTrue(config2.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(100)))
        XCTAssertFalse(config2.shouldValidateCertificate(forHost: secondaryHost, at: Date()))
    }
    
    func test_TrustConfiguration_properlyValidatesCertificates() {
        guard let domainConfig = try? TrustConfiguration.DomainConfiguration(domain: defaultHost, certificates: [TestCertificates.google]) else {
            return XCTFail("Unable to load testing certificate")
        }
        
        XCTAssertTrue(domainConfig.validate(against: TestCertificates.google))
        XCTAssertFalse(domainConfig.validate(against: TestCertificates.apple))
    }
    
    func test_TrustConfiguration_properlyValidatesCertificateHashes() {
        let domainConfig = TrustConfiguration.DomainConfiguration(domain: defaultHost, encodedPinningHashes: ["ivJZzhltgbIeXZGekPcWiLySsZ846YXSsGgyL9bjqEY="])
        XCTAssertTrue(domainConfig.validate(against: TestCertificates.google))
        XCTAssertFalse(domainConfig.validate(against: TestCertificates.apple))
    }
    
    func test_TrustValidator_testValidTrustValidates() {
        let trust = TestTrusts.leaf.trust
        
        let policies = [SecPolicyCreateBasicX509()]
        SecTrustSetPolicies(trust, policies as CFTypeRef)
        
        XCTAssertTrue(trust.isValid)
    }
    
    func test_CertificateValidator_testInvalidTrustDoesNotValidate() {
        let trust = TestTrusts.leafMissingIntermediate.trust
        
        let policies = [SecPolicyCreateBasicX509()]
        SecTrustSetPolicies(trust, policies as CFTypeRef)
        
        XCTAssertFalse(trust.isValid)
    }
    
    func test_TrustValidator_decidesOnAuthenticationSuccessWhenPinningSucceeds() {
        let trust = TestTrusts.leaf.trust
        let domainConfig = TrustConfiguration.DomainConfiguration(domain: secondaryHost, encodedPinningHashes: ["5NSH3u1+iF//AOjN69ploBrid88u75at+Zrlp8APBfM="])
        let validator = TrustValidator(configuration: TrustConfiguration(domainConfigurations: [domainConfig]))
        let result = validator.evaluate(trust, forHost: secondaryHost)
        
        switch result {
        case .allow: break
        default: XCTFail("This trust should pass pinning validation.")
        }
    }
    
    func test_TrustValidator_decidesOnAuthenticationCancellationWhenPinningFails() {
        let trust = TestTrusts.leafMissingIntermediate.trust
        let domainConfig = TrustConfiguration.DomainConfiguration(domain: secondaryHost, encodedPinningHashes: ["5NSH3u1+iF//AOjN69ploBrid88u75at+Zrlp8APBfM="])
        let validator = TrustValidator(configuration: TrustConfiguration(domainConfigurations: [domainConfig]))
        let result = validator.evaluate(trust, forHost: secondaryHost)
        
        switch result {
        case .block: break
        default: XCTFail("This trust should fail pinning validation.")
        }
    }
    
    func test_TrustValidator_doesNothingWhenPinningDoesNotOccur() {
        let domainConfig = TrustConfiguration.DomainConfiguration(domain: secondaryHost, encodedPinningHashes: ["5NSH3u1+iF//AOjN69ploBrid88u75at+Zrlp8APBfM="])
        let validator = TrustValidator(configuration: TrustConfiguration(domainConfigurations: [domainConfig]))
        
        let challenge = TestAuthenticationChallenge(host: defaultHost, serverTrust: TestTrusts.leaf.trust)
        let result = validator.handle(challenge: challenge, handler: { _, _ in })
        XCTAssertTrue(result)
        
        let challenge2 = TestAuthenticationChallenge(host: secondaryHost, authenticationMethod: "", serverTrust: TestTrusts.leaf.trust)
        let result2 = validator.handle(challenge: challenge2, handler: { _, _ in })
        XCTAssertFalse(result2)
        
        let challenge3 = TestAuthenticationChallenge(host: secondaryHost, serverTrust: nil)
        let result3 = validator.handle(challenge: challenge3, handler: { _, _ in })
        XCTAssertFalse(result3)
    }
    
    func test_TrustValidator_pinningDoesNotOccurBecauseMisconfiguration() {
        let domainConfig = TrustConfiguration.DomainConfiguration(domain: secondaryHost, encodedPinningHashes: ["5NSH3u1+iF//AOjN69ploBrid88u75at+Zrlp8APBfM="])
        let validator = TrustValidator(configuration: TrustConfiguration(domainConfigurations: [domainConfig]))
        
        switch validator.evaluate(TestTrusts.leaf.trust, forHost: defaultHost) {
        case .notPinned: break
        default: XCTFail("This validation should not occur.")
        }
    }
    
    func test_TrustValidator_returnsBlockDispositionWhenConfigurationEnforcesPinning() {
        let exp = expectation(description: "validation")
        let domainConfig = TrustConfiguration.DomainConfiguration(domain: secondaryHost, encodedPinningHashes: ["aaaaaaaaaaaaaaa"])
        let validator = TrustValidator(configuration: TrustConfiguration(domainConfigurations: [domainConfig]))

        let challenge = TestAuthenticationChallenge(host: secondaryHost, authenticationMethod: NSURLAuthenticationMethodServerTrust, serverTrust: TestTrusts.leaf.trust)
        validator.handle(challenge: challenge) { disposition, _ in
            switch disposition {
            case .cancelAuthenticationChallenge: break
            default: XCTFail("When enforcing pinning, a failure to pin should cancel the challenge")
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_TrustValidator_returnsAllowDispositionWhenConfigurationIsNotEnforcingPinning() {
        let exp = expectation(description: "validation")
        let domainConfig = TrustConfiguration.DomainConfiguration(domain: secondaryHost, enforced: false, encodedPinningHashes: ["aaaaaaaaaaaaaaa"])
        let validator = TrustValidator(configuration: TrustConfiguration(domainConfigurations: [domainConfig]))
        
        let challenge = TestAuthenticationChallenge(host: secondaryHost, authenticationMethod: NSURLAuthenticationMethodServerTrust, serverTrust: TestTrusts.leaf.trust)
        validator.handle(challenge: challenge) { disposition, _ in
            switch disposition {
            case .performDefaultHandling: break
            default: XCTFail("When enforcing pinning, a failure to pin should not cancel the challenge")
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

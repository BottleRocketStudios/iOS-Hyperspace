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
    
    struct TestAuthenticationChallenge {
        let host: String
        let authenticationMethod: String = NSURLAuthenticationMethodServerTrust
        let serverTrust: SecTrust?
    }
    
    private let defaultHost = "apple.com"
    private let secondaryHost = "google.com"
    
    func test_DomainPinningConfiguration_detectsSubdomains() {
        let config = PinningConfiguration.DomainConfiguration(domain: defaultHost, pinningHashes: [Data()])
        XCTAssertTrue(config.shouldValidateCertificate(forHost: defaultHost))
        XCTAssertTrue(config.shouldValidateCertificate(forHost: "dev.\(defaultHost)"))
        XCTAssertTrue(config.shouldValidateCertificate(forHost: "x.y.\(defaultHost)"))

        let config2 = PinningConfiguration.DomainConfiguration(domain: defaultHost, includeSubdomains: false, pinningHashes: [Data()])
        XCTAssertFalse(config2.shouldValidateCertificate(forHost: "dev.\(defaultHost)"))
        XCTAssertFalse(config2.shouldValidateCertificate(forHost: "x.y.\(defaultHost)"))
    }

    func test_DomainPinningConfiguration_enforcesOnlyOwnDomain() {
        let config = PinningConfiguration.DomainConfiguration(domain: defaultHost, pinningHashes: [Data()])
        XCTAssertTrue(config.shouldValidateCertificate(forHost: defaultHost))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: ""))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: "google.com"))
    }

    func test_DomainPinningConfiguration_enforcesOnlyBeforeExpiration() {
        let nonExpiringConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, pinningHashes: [Data()])
        XCTAssertTrue(nonExpiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date()))
        XCTAssertTrue(nonExpiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(1000)))
        XCTAssertTrue(nonExpiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(1000000)))

        let expiration = Date().addingTimeInterval(100)
        let expiringConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, pinningHashes: [Data()], expiration: expiration)
        XCTAssertTrue(expiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date()))
        XCTAssertTrue(expiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(99)))
        XCTAssertFalse(expiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(1001)))
    }

    func test_DomainPinningConfiguration_finalDispositionForFailedValidation() {
        let enforcedConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, enforced: true, pinningHashes: [Data()])
        XCTAssertEqual(enforcedConfig.dispositionForFailedValidation, .cancelAuthenticationChallenge)

        let unenforcedConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, enforced: false, pinningHashes: [Data()])
        XCTAssertEqual(unenforcedConfig.dispositionForFailedValidation, .performDefaultHandling)
    }

    func test_PinningConfiguration_respectsSetSemantics() {
        let config = PinningConfiguration(domainConfigurations: [.init(domain: defaultHost, pinningHashes: [Data()]),
                                                                 .init(domain: defaultHost, pinningHashes: [Data(bytes: [1, 2, 3, 4])])])
        XCTAssertEqual(config.domainConfigurations.count, 1)
        XCTAssertEqual(config.domainConfigurations.first, .init(domain: defaultHost, pinningHashes: [Data()]))
    }

    func test_PinningConfiguration_findsCorrectDomainConfigurationI() {
        let config = PinningConfiguration(domainConfigurations: [.init(domain: defaultHost, pinningHashes: [Data()]),
                                                                 .init(domain: secondaryHost, pinningHashes: [Data(bytes: [1, 2, 3, 4])])])

        XCTAssertEqual(config.domainConfiguration(forHost: defaultHost)?.domain, defaultHost)
        XCTAssertEqual(config.domainConfiguration(forHost: defaultHost)?.pinningHashes.count, 1)
        XCTAssertEqual(config.domainConfiguration(forHost: defaultHost)?.pinningHashes.first, Data())
        
        XCTAssertEqual(config.domainConfiguration(forHost: secondaryHost)?.domain, secondaryHost)
        XCTAssertEqual(config.domainConfiguration(forHost: secondaryHost)?.pinningHashes.count, 1)
        XCTAssertEqual(config.domainConfiguration(forHost: secondaryHost)?.pinningHashes.first, Data(bytes: [1, 2, 3, 4]))

        XCTAssertNil(config.domainConfiguration(forHost: "bbc.com"))
    }

    func test_PinningConfiguration_finalDispositionForFailedValidation() {
        let domainConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, enforced: true, pinningHashes: [Data()])
        let config = PinningConfiguration(domainConfigurations: [domainConfig])

        XCTAssertEqual(config.authenticationDispositionForFailedValidation(forHost: defaultHost), .cancelAuthenticationChallenge)
        XCTAssertEqual(config.authenticationDispositionForFailedValidation(forHost: secondaryHost), .performDefaultHandling)

        let domainConfig2 = PinningConfiguration.DomainConfiguration(domain: defaultHost, enforced: false, pinningHashes: [Data()])
        let config2 = PinningConfiguration(domainConfigurations: [domainConfig2])

        XCTAssertEqual(config2.authenticationDispositionForFailedValidation(forHost: defaultHost), .performDefaultHandling)
    }

    func test_PinningConfiguration_enforcesOnlyBeforeExpiration() {
        let expiration = Date().addingTimeInterval(100)
        let domainConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, enforced: true, pinningHashes: [Data()], expiration: expiration)
        let config = PinningConfiguration(domainConfigurations: [domainConfig])

        XCTAssertTrue(config.shouldValidateCertificate(forHost: defaultHost, at: Date()))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: defaultHost, at: expiration.addingTimeInterval(1)))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: secondaryHost, at: expiration.addingTimeInterval(1)))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: secondaryHost, at: Date()))

        let domainConfig2 = PinningConfiguration.DomainConfiguration(domain: defaultHost, enforced: true, pinningHashes: [Data()])
        let config2 = PinningConfiguration(domainConfigurations: [domainConfig2])

        XCTAssertTrue(config2.shouldValidateCertificate(forHost: defaultHost, at: Date()))
        XCTAssertTrue(config2.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(100)))
        XCTAssertFalse(config2.shouldValidateCertificate(forHost: secondaryHost, at: Date()))
    }
    
    func test_PinningConfiguration_properlyValidatesCertificates() {
        guard let googleCert = certificate(named: "google"), let appleCert = certificate(named: "apple"),
            let domainConfig = try? PinningConfiguration.DomainConfiguration(domain: defaultHost, certificates: [googleCert])else { return XCTFail("Unable to load testing certificate") }
        
        XCTAssertTrue(domainConfig.validate(against: googleCert))
        XCTAssertFalse(domainConfig.validate(against: appleCert))
    }
    
    func test_PinningConfiguration_properlyValidatesCertificateHashes() {
        guard let googleCert = certificate(named: "google"), let appleCert = certificate(named: "apple") else { return XCTFail("Unable to load testing certificate") }
        
        let domainConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, encodedPinningHashes: ["ivJZzhltgbIeXZGekPcWiLySsZ846YXSsGgyL9bjqEY="])
        XCTAssertTrue(domainConfig.validate(against: googleCert))
        XCTAssertFalse(domainConfig.validate(against: appleCert))
    }
    
    func test_CertificateValidator_decidesOnAuthenticationSuccessWhenPinningSucceeds() {
    }
    
    func test_CertificateValidator_decidesOnAuthenticationCancellationWhenPinningFails() {
    }
    
    func test_CertificateValidator_doesNothingWhenPinningDoesNotOccur() {
    }
    
    func test_CertificateValidator_pinningDoesNotOccurBecauseOfDomainMismatch() {
    }
    
    func test_CertificateValidator_pinningDoesNotOccurBecauseOfExpirationTime() {
    }
    
    func test_CertificateValidator_pinningDoesNotOccurBecauseOfUnconfiguredSubdomainUsage() {
    }
}

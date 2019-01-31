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
    
    private let defaultHost = "apple.com"
    private let secondaryHost = "google.com"
    
    func test_DomainPinningConfiguration_enforcesOnlyOwnDomain() {
        let config = PinningConfiguration.DomainConfiguration(domain: defaultHost, certificate: Data())
        XCTAssertTrue(config.shouldValidateCertificate(forHost: defaultHost))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: ""))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: "google.com"))
    }
    
    func test_DomainPinningConfiguration_enforcesOnlyBeforeExpiration() {
        let nonExpiringConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, certificate: Data())
        XCTAssertTrue(nonExpiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date()))
        XCTAssertTrue(nonExpiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(1000)))
        XCTAssertTrue(nonExpiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(1000000)))
        
        let expiration = Date().addingTimeInterval(100)
        let expiringConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, certificate: Data(), expiration: expiration)
        XCTAssertTrue(expiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date()))
        XCTAssertTrue(expiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(99)))
        XCTAssertFalse(expiringConfig.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(1001)))
    }
    
    func test_DomainPinningConfiguration_finalDispositionForFailedValidation() {
        let enforcedConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, enforced: true, certificate: Data())
        XCTAssertEqual(enforcedConfig.dispositionForFailedValidation, .cancelAuthenticationChallenge)
        
        let unenforcedConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, enforced: false, certificate: Data())
        XCTAssertEqual(unenforcedConfig.dispositionForFailedValidation, .performDefaultHandling)
    }
    
    func test_PinningConfiguration_respectsSetSemantics() {
        let config = PinningConfiguration(domainConfigurations: [.init(domain: defaultHost, certificate: Data()),
                                                                 .init(domain: defaultHost, certificate: Data(bytes: [1, 2, 3, 4]))])
        XCTAssertEqual(config.domainConfigurations.count, 1)
        XCTAssertEqual(config.domainConfigurations.first, .init(domain: defaultHost, certificate: Data()))
    }
    
    func test_PinningConfiguration_findsCorrectDomainConfigurationI() {
        let config = PinningConfiguration(domainConfigurations: [.init(domain: defaultHost, certificate: Data()),
                                                                 .init(domain: secondaryHost, certificate: Data(bytes: [1, 2, 3, 4]))])
        
        XCTAssertEqual(config.domainConfiguration(forHost: defaultHost)?.domain, defaultHost)
        XCTAssertEqual(config.domainConfiguration(forHost: defaultHost)?.certificate, Data())
        
        XCTAssertEqual(config.domainConfiguration(forHost: secondaryHost)?.domain, secondaryHost)
        XCTAssertEqual(config.domainConfiguration(forHost: secondaryHost)?.certificate, Data(bytes: [1, 2, 3, 4]))
        
        XCTAssertNil(config.domainConfiguration(forHost: "bbc.com"))
    }
    
    func test_PinningConfiguration_finalDispositionForFailedValidation() {
        let domainConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, enforced: true, certificate: Data())
        let config = PinningConfiguration(domainConfigurations: [domainConfig])
        
        XCTAssertEqual(config.authenticationDispositionForFailedValidation(forHost: defaultHost), .cancelAuthenticationChallenge)
        XCTAssertEqual(config.authenticationDispositionForFailedValidation(forHost: secondaryHost), .performDefaultHandling)
        
        let domainConfig2 = PinningConfiguration.DomainConfiguration(domain: defaultHost, enforced: false, certificate: Data())
        let config2 = PinningConfiguration(domainConfigurations: [domainConfig2])
        
        XCTAssertEqual(config2.authenticationDispositionForFailedValidation(forHost: defaultHost), .performDefaultHandling)
    }
    
    func test_PinningConfiguration_enforcesOnlyBeforeExpiration() {
        let expiration = Date().addingTimeInterval(100)
        let domainConfig = PinningConfiguration.DomainConfiguration(domain: defaultHost, enforced: true, certificate: Data(), expiration: expiration)
        let config = PinningConfiguration(domainConfigurations: [domainConfig])
        
        XCTAssertTrue(config.shouldValidateCertificate(forHost: defaultHost, at: Date()))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: defaultHost, at: expiration.addingTimeInterval(1)))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: secondaryHost, at: expiration.addingTimeInterval(1)))
        XCTAssertFalse(config.shouldValidateCertificate(forHost: secondaryHost, at: Date()))
        
        let domainConfig2 = PinningConfiguration.DomainConfiguration(domain: defaultHost, enforced: true, certificate: Data())
        let config2 = PinningConfiguration(domainConfigurations: [domainConfig2])
        
        XCTAssertTrue(config2.shouldValidateCertificate(forHost: defaultHost, at: Date()))
        XCTAssertTrue(config2.shouldValidateCertificate(forHost: defaultHost, at: Date().addingTimeInterval(100)))
        XCTAssertFalse(config2.shouldValidateCertificate(forHost: secondaryHost, at: Date()))
    }
}

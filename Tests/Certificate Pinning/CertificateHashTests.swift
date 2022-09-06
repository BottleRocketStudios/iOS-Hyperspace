//
//  CertificateHashTests.swift
//  Tests
//
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

@available(*, deprecated)
class CertificateHashTests: XCTestCase {

    // MARK: - Tests
    func test_CertificateHasher_publicKeyHashGenerationFromCertificate() {        
        do {
            let googleHash = try CertificateHasher.pinningHash(for: TestCertificates.google).base64EncodedString()
            let appleHash = try CertificateHasher.pinningHash(for: TestCertificates.apple).base64EncodedString()
            let bbcHash = try CertificateHasher.pinningHash(for: TestCertificates.bbc).base64EncodedString()
            
            XCTAssertEqual(googleHash, "ivJZzhltgbIeXZGekPcWiLySsZ846YXSsGgyL9bjqEY=")
            XCTAssertEqual(appleHash, "WHaeY9m+VRkoyxfmPwZnqJZ5s7sRUG1nZ2cWQUvDNF4=")
            XCTAssertEqual(bbcHash, "MDwACTKSWYxpTDvC04QE9LOdDKs+ilnSA60v6Dez43M=")
        } catch {
            XCTFail("Unable to derive a pinning hash from one or more certificates.")
        }
    }
    
    func test_CertificateHasher_keyTypesIdentifyCorrectly() {
        let algo1 = CertificateHasher.PublicKeyAlgorithm(keyType: kSecAttrKeyTypeRSA, keySize: 2048)
        let algo2 = CertificateHasher.PublicKeyAlgorithm(keyType: kSecAttrKeyTypeRSA, keySize: 4096)
        let algo3 = CertificateHasher.PublicKeyAlgorithm(keyType: kSecAttrKeyTypeECSECPrimeRandom, keySize: 256)
        let algo4 = CertificateHasher.PublicKeyAlgorithm(keyType: kSecAttrKeyTypeECSECPrimeRandom, keySize: 384)
        
        XCTAssertEqual(algo1, CertificateHasher.PublicKeyAlgorithm.rsa2048)
        XCTAssertEqual(algo2, CertificateHasher.PublicKeyAlgorithm.rsa4096)
        XCTAssertEqual(algo3, CertificateHasher.PublicKeyAlgorithm.ecDsaSecp256r1)
        XCTAssertEqual(algo4, CertificateHasher.PublicKeyAlgorithm.ecDsaSecp384r1)
        
        XCTAssertEqual(algo1?.asn1HeaderBytes, CertificateHasher.PublicKeyAlgorithm.rsa2048.asn1HeaderBytes)
        XCTAssertEqual(algo2?.asn1HeaderBytes, CertificateHasher.PublicKeyAlgorithm.rsa4096.asn1HeaderBytes)
        XCTAssertEqual(algo3?.asn1HeaderBytes, CertificateHasher.PublicKeyAlgorithm.ecDsaSecp256r1.asn1HeaderBytes)
        XCTAssertEqual(algo4?.asn1HeaderBytes, CertificateHasher.PublicKeyAlgorithm.ecDsaSecp384r1.asn1HeaderBytes)
    }
}

//
//  CertificateHashTests.swift
//  Hyperspace
//
//  Created by Will McGinty on 1/30/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import XCTest
@testable import Hyperspace

class CertificateHashTests: XCTestCase {
    
    func test_CertificateHasher_publicKeyHashGenerationFromCertificate() {
        guard let googleCert = certificate(named: "google"), let appleCert = certificate(named: "apple"),
            let bbcCert = certificate(named: "bbc") else {
                return XCTFail("Could not locate test certificates in test bundle.")
        }
        
        do {
            let googleHash = try CertificateHasher.pinningHash(for: googleCert).base64EncodedString()
            let appleHash = try CertificateHasher.pinningHash(for: appleCert).base64EncodedString()
            let bbcHash = try CertificateHasher.pinningHash(for: bbcCert).base64EncodedString()
            
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

extension XCTestCase {

    func certificate(named: String) -> SecCertificate? {
        guard let certPath = Bundle(for: CertificateHashTests.self).url(forResource: named, withExtension: "der"),
            let certificateData = try? Data(contentsOf: certPath),
            let certificate = SecCertificateCreateWithData(kCFAllocatorDefault, certificateData as CFData) else {
                return nil
        }
        
        return certificate
    }
    
    func createdTrust(with certificates: [SecCertificate], anchorCertificates: [SecCertificate]) -> SecTrust? {
            var trust: SecTrust?
            let result = SecTrustCreateWithCertificates(certificates as CFTypeRef, SecPolicyCreateSSL(true, nil), &trust)
            
            guard result == errSecSuccess else { return nil }
            
            if let trust = trust {
                if SecTrustSetAnchorCertificates(trust, anchorCertificates as CFArray) != errSecSuccess {
                    return nil
                }
                
                let verifyTime: CFAbsoluteTime = 475163640.0
                let testVerifyDate: CFDate = CFDateCreate(nil, verifyTime)
                SecTrustSetVerifyDate(trust, testVerifyDate)
                return trust
            }
        
            return nil
        }
}

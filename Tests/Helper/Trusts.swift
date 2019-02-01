//
//  XCTestCase+Certs.swift
//  Hyperspace
//
//  Created by Will McGinty on 2/1/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import XCTest

struct TestCertificates {
    
    class Locator {}
    
    // Root Certificates
    static let root = TestCertificates.certificate(filename: "root", type: "cer")
    
    // Intermediate Certificates
    static let intermediate = TestCertificates.certificate(filename: "intermediate", type: "cer")
    
    // Leaf Certificates
    static let leaf = TestCertificates.certificate(filename: "leaf", type: "cer")
    static let google = TestCertificates.certificate(filename: "google")
    static let bbc = TestCertificates.certificate(filename: "bbc")
    static let apple = TestCertificates.certificate(filename: "apple")
    
    static func certificate(filename: String, type: String = "der") -> SecCertificate {
        let filePath = Bundle(for: Locator.self).path(forResource: filename, ofType: type)!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        return SecCertificateCreateWithData(nil, data as CFData)!
    }
}

enum TestTrusts {
    
    // Leaf Trusts
    case leaf
    
    // Invalid Trusts
    case leafMissingIntermediate
    
    var trust: SecTrust {
        let trust: SecTrust
        
        switch self {
        case .leaf:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leaf,
                TestCertificates.intermediate,
                TestCertificates.root
                ])
        case .leafMissingIntermediate:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.leaf,
                TestCertificates.root
                ])
        }
        
        return trust
    }
    
    static func trustWithCertificates(_ certificates: [SecCertificate], onlyTestRootAsAnchor: Bool = true) -> SecTrust {
        let policy = SecPolicyCreateBasicX509()
        
        var trust: SecTrust?
        SecTrustCreateWithCertificates(certificates as CFTypeRef, policy, &trust)
        
        SecTrustSetAnchorCertificates(trust!, [TestCertificates.root] as CFArray)
        SecTrustSetAnchorCertificatesOnly(trust!, true)
        
        return trust!
    }
}

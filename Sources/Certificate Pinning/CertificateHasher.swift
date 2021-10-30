//
//  CertificateHasher.swift
//  Hyperspace
//
//  Created by Will McGinty on 1/30/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import CommonCrypto

@available(iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *)
struct CertificateHasher {
    
    enum Error: Swift.Error {
        case contextError //There was an issue performing the cryptographic operations to retrieve the pinning hash
        case unableToRetrievePublicKey //There was an issue extracting the public key from the certificate
        case unsupportedAlgorithm //The public key is utilizing an unsupporting algorithm. RSA2048, RSA4096, ECSECPrimeRandom256 and ECSECPrimeRandom384 are supported
    }
    
    enum PublicKeyAlgorithm: String {
        case rsa2048
        case rsa4096
        case ecDsaSecp256r1
        case ecDsaSecp384r1
        
        var asn1HeaderBytes: [UInt8] {
            switch self {
            case .rsa2048:
                return [ 0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00 ]
            case .rsa4096:
                return [ 0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0f, 0x00 ]
            case .ecDsaSecp256r1:
                return [ 0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00 ]
            case .ecDsaSecp384r1:
                return [ 0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x22, 0x03, 0x62, 0x00 ]
            }
        }

        init?(keyType: CFString, keySize: UInt) {
            switch (keyType, keySize) {
            case (kSecAttrKeyTypeRSA, 2048): self = .rsa2048
            case (kSecAttrKeyTypeRSA, 4096): self = .rsa4096
            case (kSecAttrKeyTypeECSECPrimeRandom, 256): self = .ecDsaSecp256r1
            case (kSecAttrKeyTypeECSECPrimeRandom, 384): self = .ecDsaSecp384r1
            default: return nil
            }
        }
    }
    
    static func pinningHash(for certificate: SecCertificate) throws -> Data {
        return try sha256PublicKeyData(from: certificate)
    }
    
    static func checkValidity(of trust: SecTrust) -> Bool {
        var result: CFError?
        let status = SecTrustEvaluateWithError(trust, &result)
        
        return status || result == nil
    }
}

// MARK: - Helper
@available(iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *)
private extension CertificateHasher {
    
    // MARK: - PublicKey Internal Subtype
    struct PublicKey {
        let key: SecKey
        let type: CFString
        let size: UInt
        
        init(certificate: SecCertificate) throws {
            guard let key = secKey(from: certificate), let attributes = attributes(from: key) else { throw Error.unableToRetrievePublicKey }
            
            self.key = key
            self.type = attributes.type
            self.size = attributes.size
        }
    }
    
    static func sha256PublicKeyData(from certificate: SecCertificate) throws -> Data {
        let pubKey = try PublicKey(certificate: certificate)
        guard let data = SecKeyCopyExternalRepresentation(pubKey.key, nil) else { throw Error.unableToRetrievePublicKey }
        return try sha256PublicKeyData(from: data, with: pubKey)
    }
    
    static func sha256PublicKeyData(from certificateData: CFData, with publicKey: PublicKey) throws -> Data {
        guard let publicKeyHash = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else { throw Error.contextError }
        let keyData = certificateData as NSData
        
        var shaCtx = CC_SHA256_CTX()
        CC_SHA256_Init(&shaCtx)
        
        //Add the missing ASN1 header
        guard let algorithm = PublicKeyAlgorithm(keyType: publicKey.type, keySize: publicKey.size) else { throw Error.unsupportedAlgorithm }
        let header = algorithm.asn1HeaderBytes

        //Add the appropriate header and public key
        CC_SHA256_Update(&shaCtx, header, CC_LONG(header.count))
        CC_SHA256_Update(&shaCtx, keyData.bytes, CC_LONG(keyData.length))
        
        let publicKeyHashBytes = UnsafeMutableRawPointer(publicKeyHash.mutableBytes).assumingMemoryBound(to: UInt8.self)
        CC_SHA256_Final(publicKeyHashBytes, &shaCtx)
        
        return publicKeyHash as Data
    }
    
    static func secKey(from certificate: SecCertificate) -> SecKey? {
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &trust)
        
        /*We do not need to evaluate trust here as we are simply looking to extract a public key - explicit evaluation is achieved by calling `checkValidity(of:)`.
            This is useful, for instance, when attempting to create a pinning hash for an invalid or expired certificate. If we were to validate on creation, we would not be able to test this. */
        guard let securityTrust = trust, status == errSecSuccess else { return nil }
        return SecTrustCopyPublicKey(securityTrust)
    }

    static func attributes(from publicKey: SecKey) -> (type: CFString, size: UInt)? {
        guard let attributes = SecKeyCopyAttributes(publicKey) as? [String: AnyObject],
            let size = attributes[kSecAttrKeySizeInBits as String] as? NSNumber,
            let type = attributes[kSecAttrKeyType as String] as? String else { return nil }
        return (type as CFString, size.uintValue)
    }
}

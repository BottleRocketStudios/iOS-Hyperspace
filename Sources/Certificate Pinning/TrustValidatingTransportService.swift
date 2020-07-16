//
//  TrustValidatingTransportService.swift
//  Hyperspace
//
//  Created by Will McGinty on 2/1/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// This class builds upon the `Transporting` to offer a quick option for performing server trust validation.
@available(iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *)
public class TrustValidatingTransportService: Transporting {
    
    class SessionDelegate: NSObject, URLSessionDelegate {
        
        // MARK: - Properties
        
        let configuration: TrustConfiguration
        
        // MARK: - Initializers
        
        init(configuration: TrustConfiguration) {
            self.configuration = configuration
        }
        
        // MARK: - TrustValidatingURLSessionDelegate conformance to URLSessionDelegate
        
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            let validator = TrustValidator(configuration: configuration)
            
            guard validator.canHandle(challenge: challenge) else {
                //This was NOT a server trust authentication challenge - further input is required
                return completionHandler(.performDefaultHandling, nil)
            }
            
            validator.handle(challenge: challenge, handler: completionHandler)
            //The server trust authentication challenge was handled (for both allow and blocks) - not further input is required
        }
    }

    // MARK: Properties
    
    private let transportService: TransportService
    private let sessionTrustValidator: SessionDelegate
    
    // MARK: - Initializers
    
    /// Returns an instance of `TrustValidatingTransportService` capable of performing server trust validation based on the provided configuration.
    ///
    /// - Parameters:
    ///   - trustConfiguration: The configuration object used to govern the rules as to how server trust validation is performed on the network service.
    ///   - sessionConfiguration: The configuration of the `URLSession` object used by the `TransportService`.
    ///   - networkActivityIndicatable: An object capable of displaying current network activity visually to the user.
    public init(trustConfiguration: TrustConfiguration, sessionConfiguration: URLSessionConfiguration = .default, networkActivityIndicatable: NetworkActivityIndicatable? = nil) {
        let trustDelegate = SessionDelegate(configuration: trustConfiguration)
        let session = URLSession(configuration: sessionConfiguration, delegate: trustDelegate, delegateQueue: .main)
    
        self.transportService = TransportService(session: session, networkActivityIndicatable: networkActivityIndicatable)
        self.sessionTrustValidator = trustDelegate
    }
    
    // MARK: - TrustValidatingTransportService conformance to Transporting
    
    public func execute(request: URLRequest, completion: @escaping (TransportResult) -> Void) {
        transportService.execute(request: request, completion: completion)
    }
    
    public func cancelTask(for request: URLRequest) {
        transportService.cancelTask(for: request)
    }
    
    public func cancelAllTasks() {
        transportService.cancelAllTasks()
    }
}

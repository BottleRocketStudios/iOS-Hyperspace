//
//  TrustValidatingNetworkService.swift
//  Hyperspace-iOSExample
//
//  Created by Will McGinty on 2/1/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

@available(iOSApplicationExtension 10.0, *)
@available(watchOSApplicationExtension 3.0, *)

/// <#Description#>
public class TrustValidatingNetworkService: NetworkServiceProtocol {
    
    private class TrustValidatingURLSessionDelegate: NSObject, URLSessionDelegate {
        
        // MARK: - Properties
        
        let configuration: TrustConfiguration
        
        // MARK: - Initializers
        
        init(configuration: TrustConfiguration) {
            self.configuration = configuration
        }
        
        // MARK: - TrustValidatingURLSessionDelegate conformance to URLSessionDelegate
        
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            let validator = TrustValidator(configuration: configuration)
            if validator.handle(challenge: challenge, handler: completionHandler) {
                debugPrint("Server Trust validation handled.")
                //The server trust authentication challenge was handled (for both allow and blocks) - not further input is required
            } else {
                //This was NOT a server trust authentication challenge - further input is required
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }

    // MARK: Properties
    
    private let networkService: NetworkService
    private let sessionTrustValidator: TrustValidatingURLSessionDelegate
    
    // MARK: - Initializers
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - trustConfiguration: <#trustConfiguration description#>
    ///   - sessionConfiguration: <#sessionConfiguration description#>
    ///   - networkActivityIndicatable: <#networkActivityIndicatable description#>
    public init(trustConfiguration: TrustConfiguration, sessionConfiguration: URLSessionConfiguration = .default, networkActivityIndicatable: NetworkActivityIndicatable? = nil) {
        let trustDelegate = TrustValidatingURLSessionDelegate(configuration: trustConfiguration)
        let session = URLSession(configuration: sessionConfiguration, delegate: trustDelegate, delegateQueue: .main)
        let networkActivityController = networkActivityIndicatable.map { NetworkActivityController(indicator: $0) }
        
        self.networkService = NetworkService(session: session, networkActivityController: networkActivityController)
        self.sessionTrustValidator = trustDelegate
    }
    
    // MARK: - TrustValidatingNetworkService conformance to NetworkServiceProtocol
    
    public func execute(request: URLRequest, completion: @escaping NetworkServiceCompletion) {
        networkService.execute(request: request, completion: completion)
    }
    
    public func cancelTask(for request: URLRequest) {
        networkService.cancelTask(for: request)
    }
    
    public func cancelAllTasks() {
        networkService.cancelAllTasks()
    }
}

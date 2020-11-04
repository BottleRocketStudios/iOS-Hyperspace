//
//  ViewController.swift
//  Hyperspace-iOSExample
//
//  Created by Tyler Milner on 1/27/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import UIKit
import Hyperspace

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet private var postTextField: UITextField!
    @IBOutlet private var serverTrustValidationToggle: UISwitch!
    
    // MARK: - Properties
    
    private let backendService = BackendService(transportService: TransportService(networkActivityIndicatable: UIApplication.shared))
    private lazy var trustValidatingBackendService: BackendService = {
        // Creates a trust configuration whereby requests to the domain 'jsonplaceholder.typicode.com' will be validated to ensure they are being served a certificate matching 'jsonplaceholder.der'
        let domainConfiguration = try? TrustConfiguration.DomainConfiguration(domain: "jsonplaceholder.typicode.com", certificates: certificate(named: "jsonplaceholder").map { [$0] } ?? [])
        let validatingTransportService = TrustValidatingTransportService(trustConfiguration: domainConfiguration.map { [$0] } ?? [],
                                                                     networkActivityIndicatable: UIApplication.shared)
        return BackendService(transportService: validatingTransportService)
    }()
    
    var preferredBackendService: BackendService {
        return serverTrustValidationToggle.isOn ? trustValidatingBackendService : backendService
    }
    
    // MARK: - IBActions
    
    @IBAction private func getUserButtonTapped(_ sender: UIButton) {
        getUser()
    }
    
    @IBAction private func createPostButtonTapped(_ sender: UIButton) {
        let title = postTextField.text ?? "<no title>"
        createPost(titled: title)
    }
    
    @IBAction private func deletePostButtonTapped(_ sender: UIButton) {
        deletePost(postId: 1)
    }
}

extension ViewController {
    private func getUser() {
        let getUserRequest = Request<User, AnyError>.getUser(withID: 1)
        
        preferredBackendService.execute(request: getUserRequest) { [weak self] result in
            debugPrint("Get user result: \(result)")
            
            switch result {
            case .success(let user):
                self?.presentAlert(titled: "Fetched user", message: "\(user)")
            case .failure(let error):
                self?.presentAlert(titled: "Error", message: "\(error)")
            }
        }
    }
    
    private func createPost(titled title: String) {
        let post = NewPost(userId: 1, title: title, body: "")
        let createPostRequest = Request<Post, AnyError>.createPost(post)
        
        preferredBackendService.execute(request: createPostRequest) { [weak self] result in
            debugPrint("Create post result: \(result)")
            
            switch result {
            case .success(let post):
                self?.presentAlert(titled: "Created post", message: "\(post)")
            case .failure(let error):
                self?.presentAlert(titled: "Error", message: "\(error)")
            }
        }
    }
    
    private func deletePost(postId: Int) {
        let deletePostRequest = Request<EmptyResponse, AnyError>.deletePost(withID: postId)
        
        preferredBackendService.execute(request: deletePostRequest) { [weak self] result in
            switch result {
            case .success:
                self?.presentAlert(titled: "Deleted Post", message: "Success")
            case .failure(let error):
                self?.presentAlert(titled: "Error", message: "\(error)")
            }
        }
    }
}

extension UIViewController {
    
    func presentAlert(titled title: String, message: String) {
        let dismissAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(dismissAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func certificate(named: String) -> SecCertificate? {
        guard let certPath = Bundle.main.url(forResource: named, withExtension: "cer"),
            let certificateData = try? Data(contentsOf: certPath),
            let certificate = SecCertificateCreateWithData(kCFAllocatorDefault, certificateData as CFData) else {
                return nil
        }
        
        return certificate
    }
}

extension UIApplication: NetworkActivityIndicatable { /* No extra conformance needed. */ }

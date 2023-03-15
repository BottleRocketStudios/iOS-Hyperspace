//
//  ViewController.swift
//  Example
//
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import UIKit
import Hyperspace

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet private var postTextField: UITextField!
    @IBOutlet private var serverTrustValidationToggle: UISwitch!
    
    // MARK: - Properties
    private let backendService = BackendService(transportService: TransportService())

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
        Task {
            do {
                let getUserRequest = Request<User>.getUser(withID: 1)
                let user = try await backendService.execute(request: getUserRequest)
                presentAlert(titled: "Fetched user", message: "\(user)")
            } catch {
                presentAlert(titled: "Error", message: "\(error)")
            }
        }
    }
    
    private func createPost(titled title: String) {
        Task {
            do {
                let post = NewPost(userId: 1, title: title, body: "")
                let createPostRequest = Request<Post>.createPost(post)
                let createdPost = try await backendService.execute(request: createPostRequest)
                presentAlert(titled: "Created post", message: "\(createdPost)")
            } catch {
                presentAlert(titled: "Error", message: "\(error)")
            }
        }
    }
    
    private func deletePost(postId: Int) {
        Task {
            do {
                let deletePostRequest = Request<Void>.deletePost(withID: postId)
                try await backendService.execute(request: deletePostRequest)
                presentAlert(titled: "Deleted Post", message: "Success")
            } catch {
                presentAlert(titled: "Error", message: "\(error)")
            }
        }
    }
}

// MARK: - Helper
extension UIViewController {
    
    func presentAlert(titled title: String, message: String) {
        let dismissAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(dismissAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

//
//  ViewController.swift
//  Hyperspace_Example_tvOS
//
//  Created by Ryan Gant on 12/5/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import UIKit
import Hyperspace

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet private var postTextField: UITextField!
    
    // MARK: - Properties
    
    private let backendService = BackendService()
    
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
        let getUserRequest = GetUserRequest(userId: 1)
        
        backendService.execute(request: getUserRequest) { [weak self] (result) in
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
        let createPostRequest = CreatePostRequest(newPost: post)
        
        backendService.execute(request: createPostRequest) { [weak self] (result) in
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
        let deletePostRequest = DeletePostRequest(postId: postId)
        
        backendService.execute(request: deletePostRequest) { [weak self] (result) in
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
}

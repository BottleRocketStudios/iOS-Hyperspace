//
//  InterfaceController.swift
//  Hyperspace-watchOSExample Extension
//
//  Created by Tyler Milner on 1/27/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import WatchKit
import Foundation
import Hyperspace

class InterfaceController: WKInterfaceController {
    
    // MARK: - Properties
    
    private let backendService = BackendService()
    
    // MARK: - IBActions
    
    @IBAction private func getUserButtonTapped(_ sender: WKInterfaceButton) {
        getUser()
    }
    
    @IBAction private func createPostButtonTapped(_ sender: WKInterfaceButton) {
        let title = "Test"
        createPost(titled: title)
    }
    
    @IBAction private func deletePostButtonTapped(_ sender: WKInterfaceButton) {
        deletePost(postId: 1)
    }
}

extension InterfaceController {
    private func getUser() {
        let getUserRequest = Request<User, AnyError>.getUser(withID: 1)

        backendService.execute(request: getUserRequest) { [weak self] result in
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
        
        backendService.execute(request: createPostRequest) { [weak self] result in
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
        
        backendService.execute(request: deletePostRequest) { [weak self] result in
            switch result {
            case .success:
                self?.presentAlert(titled: "Deleted Post", message: "Success")
            case .failure(let error):
                self?.presentAlert(titled: "Error", message: "\(error)")
            }
        }
    }
}

extension WKInterfaceController {
    func presentAlert(titled title: String, message: String) {
        let dismissAction = WKAlertAction(title: "OK", style: .default) {
            //Do nothing
        }
        presentAlert(withTitle: title, message: message, preferredStyle: .alert, actions: [dismissAction])
    }
}

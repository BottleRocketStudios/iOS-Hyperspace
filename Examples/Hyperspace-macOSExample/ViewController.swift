//
//  ViewController.swift
//  Hyperspace-macOSExample
//
//  Created by Adam Brzozowski on 2/1/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Cocoa
import Hyperspace

class ViewController: NSViewController {

    @IBOutlet private var postTextField: NSTextField!
    
    private let backendService = BackendService(networkService: NetworkService(networkActivityIndicatable: NSApplication.shared))
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction private func getUserButtonTapped(_ sender: NSButton) {
        getUser()
    }
    
    @IBAction private func createPostButtonTapped(_ sender: NSButton) {
        let title = postTextField.stringValue 
        createPost(titled: title)
    }
    
    @IBAction private func deletePostButtonTapped(_ sender: NSButton) {
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

extension NSViewController {
    func presentAlert(titled title: String, message: String) {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        
        alert.runModal()
    }
}

extension NSApplication: NetworkActivityIndicatable { /* No extra conformance needed. */ }

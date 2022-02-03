//
//  ViewController.swift
//  macOS Example
//
//  Created by Andrew Winn on 2/2/22.
//  Copyright © 2022 Bottle Rocket Studios. All rights reserved.
//

import Cocoa
import Hyperspace

class ViewController: NSViewController {

    // MARK: - IBOutlets
    @IBOutlet private var postTextField: NSTextField!

    // MARK: - Properties
    private let backendService = BackendService()

    // MARK: - IBActions
    @IBAction private func getUserButtonTapped(_ sender: NSButton) {
        getUser()
    }

    @IBAction private func createPostButtonTapped(_ sender: NSButton) {
        let stringValue = postTextField.stringValue
        let title = stringValue.isEmpty ? "<no title>" : stringValue
        createPost(titled: title)
    }

    @IBAction private func deletePostButtonTapped(_ sender: NSButton) {
        deletePost(postId: 1)
    }
}

extension ViewController {
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

// MARK: - Helper

extension NSViewController {

    func presentAlert(titled title: String, message: String) {
        let alertView = NSAlert()
        alertView.alertStyle = .informational
        alertView.accessoryView = NSView(frame: CGRect(x: 0, y: 0, width: 300, height: 0))

        alertView.addButton(withTitle: "OK")
        alertView.messageText = title
        alertView.informativeText = message
        alertView.runModal()
    }
}

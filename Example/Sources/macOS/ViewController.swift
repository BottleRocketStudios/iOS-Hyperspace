//
//  ViewController.swift
//  macOS Example
//
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

// MARK: - Helper

private extension ViewController {

    func getUser() {
        Task {
            do {
                let getUserRequest = Request<User>.getUser(withID: 1)
                let user = try await backendService.execute(request: getUserRequest, delegate: nil)
                presentAlert(titled: "Fetched user", message: "\(user)")
            } catch {
                presentAlert(titled: "Error", message: "\(error)")
            }
        }
    }

    func createPost(titled title: String) {
        Task {
            do {
                let post = NewPost(userId: 1, title: title, body: "")
                let createPostRequest = Request<Post>.createPost(post)
                let createdPost = try await backendService.execute(request: createPostRequest, delegate: nil)
                presentAlert(titled: "Created post", message: "\(createdPost)")
            } catch {
                presentAlert(titled: "Error", message: "\(error)")
            }
        }
    }

    func deletePost(postId: Int) {
        Task {
            do {
                let deletePostRequest = Request<Void>.deletePost(withID: postId)
                try await backendService.execute(request: deletePostRequest, delegate: nil)
                presentAlert(titled: "Deleted Post", message: "Success")
            } catch {
                presentAlert(titled: "Error", message: "\(error)")
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

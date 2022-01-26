// : Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import Hyperspace

PlaygroundPage.current.needsIndefiniteExecution = true

// MARK: - Models

struct User: Decodable {
    let id: Int
    let name: String
    let username: String
    let email: String
}

struct Post: Decodable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}

struct NewPost: Encodable {
    let userId: Int
    let title: String
    let body: String
}

// MARK: - Example

/// 1. Customize the defaults for Request creation (optional)

RequestDefaults.defaultTimeout = 60 // Default timeout is 30 seconds
RequestDefaults.defaultCachePolicy = .reloadIgnoringLocalCacheData // Default cache policy is '.useProtocolCachePolicy'

/// 2. Create your concrete Request types

extension Request where Response == User, Error == AnyError {

    static func getUser(withID id: Int) -> Request<User, AnyError> {
        return Request(method: .get, url: URL(string: "https://jsonplaceholder.typicode.com/users/\(id)")!)
    }
}

extension Request where Response == Post, Error == AnyError {

    static func createPost(_ post: NewPost) -> Request<Post, AnyError> {
        return Request(method: .post, url: URL(string: "https://jsonplaceholder.typicode.com/posts")!, headers: [.contentType: .applicationJSON],
                       body: try? HTTP.Body(post))
    }
}

/// 3. Instantiate your concrete Request types

let getUserRequest = Request<User, AnyError>.getUser(withID: 1)
let createPostRequest = Request<Post, AnyError>.createPost(NewPost(userId: 1, title: "Test tile", body: "Test body"))

/// 4. Create a BackendServices to execute the requests

let backendService = BackendService()

/// 5. Execute the Request

func getUser(completion: @escaping () -> Void) {
    backendService.execute(request: getUserRequest) { result in
        switch result {
        case .success(let user):
            print("Fetched user: \(user)")
        case .failure(let error):
            print("Error fetching user: \(error)")
        }
        
        completion()
    }
}

func createPost(completion: @escaping () -> Void) {
    backendService.execute(request: createPostRequest) { result in
        switch result {
        case .success(let post):
            print("Created post: \(post)")
        case .failure(let error):
            print("Error creating post: \(error)")
        }
        
        completion()
    }
}

func executeExample() {
    getUser {
        createPost {
            PlaygroundPage.current.finishExecution()
        }
    }
}

executeExample()

// : Playground - noun: a place where people can play

import UIKit
import Hyperspace

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

extension Request where Response == User {

    static func getUser(withID id: Int) -> Request<User> {
        return Request(url: URL(string: "https://jsonplaceholder.typicode.com/users/\(id)")!)
    }
}

extension Request where Response == Post {

    static func createPost(_ post: NewPost) -> Request<Post> {
        return Request(method: .post, url: URL(string: "https://jsonplaceholder.typicode.com/posts")!, headers: [.contentType: .applicationJSON],
                       body: try? HTTP.Body.json(post))
    }
}


/// 3. Instantiate your concrete Request types

let getUserRequest = Request<User>.getUser(withID: 1)
let createPostRequest = Request<Post>.createPost(NewPost(userId: 1, title: "Test tile", body: "Test body"))

/// 4. Create a BackendServices to execute the requests

let backendService = BackendService()

/// 5. Execute the Request

func getUser() async throws {
    do {
        let user = try await backendService.execute(request: getUserRequest)
        print("Fetched user: \(user)")
    } catch {
        print("Error fetching user: \(error)")
    }
}

func createPost() async throws {
    do {
        let post = try await backendService.execute(request: createPostRequest)
        print("Created post: \(post)")
    } catch {
        print("Error creating post: \(error)")
    }
}

func executeExample() async throws {
    let user = getUser()
    let createdPost = createPost()
}

executeExample()

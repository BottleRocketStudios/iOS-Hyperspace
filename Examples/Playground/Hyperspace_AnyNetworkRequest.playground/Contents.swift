//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import Hyperspace
import Result

PlaygroundPage.current.needsIndefiniteExecution = true

// MARK: - Models

struct User: Decodable {
    let identifier: Int
    let name: String
    let username: String
    let email: String
    
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case name, username, email
    }
}

struct Post: Decodable {
    let identifier: Int
    let userId: Int
    let title: String
    let body: String
    
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case userId, title, body
    }
}

struct NewPost: Encodable {
    let userId: Int
    let title: String
    let body: String
}

// MARK: - Request

let getUserRequest = AnyNetworkRequest<User>(method: .get, url: URL(string: "http://jsonplaceholder.typicode.com/users/1")!)

let newPost = NewPost(userId: 1, title: "Test tile", body: "Test body")
let postBody = try? JSONEncoder().encode(newPost)

let createPostRequest = AnyNetworkRequest<Post>(method: .post,
                                                url: URL(string: "http://jsonplaceholder.typicode.com/posts")!,
                                                headers: [.contentType: .applicationJSON],
                                                body: postBody)

// MARK: - BackendService

let backendService = BackendService()

backendService.execute(request: getUserRequest) { (result) in
    switch result {
    case .success(let user):
        debugPrint("Fetched user: \(user)")
    case .failure(let error):
        debugPrint("Error fetching user: \(error)")
    }
    
    PlaygroundPage.current.finishExecution()
}

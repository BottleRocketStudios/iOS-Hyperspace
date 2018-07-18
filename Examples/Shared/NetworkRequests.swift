//
//  Requests.swift
//  Hyperspace_Example
//
//  Created by Tyler Milner on 7/14/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace
import Result

// MARK: - Network Request Defaults

// An extension like this can be used so that you don't have to specify them in every Request you create.
extension Request {
    static var defaultTimeout: TimeInterval {
        return 30.0
    }
    
    static var defaultCachePolicy: URLRequest.CachePolicy {
        return .useProtocolCachePolicy
    }
    
    var cachePolicy: URLRequest.CachePolicy {
        return Self.defaultCachePolicy
    }
    
    var timeout: TimeInterval {
        return Self.defaultTimeout
    }
}

// MARK: - Get User Request

struct GetUserRequest: Request {
    
    // Define the model we want to get back
    typealias ResponseType = User
    typealias ErrorType = AnyError
    
    // Define Request property values
    var method: HTTP.Method = .get
    var url: URL {
        return URL(string: "https://jsonplaceholder.typicode.com/users/\(userId)")!
    }
    var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
    var body: Data?
    
    // Define any custom properties needed
    private let userId: Int
    
    // Initializer
    init(userId: Int) {
        self.userId = userId
    }
}

// MARK: - Create Post Request

struct CreatePostRequest: Request {

    // Define the model we want to get back
    typealias ResponseType = Post
    typealias ErrorType = AnyError
    
    // Define Request property values
    var method: HTTP.Method = .post
    var url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
    var headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = [.contentType: .applicationJSON]
    var body: Data?
    
    // Define any custom properties needed
    private let newPost: NewPost
    
    // Initializer
    init(newPost: NewPost) {
        self.newPost = newPost
        body = try? JSONEncoder().encode(newPost)
    }
}

// MARK: - Delete Post Request

struct DeletePostRequest: Request {
    typealias ResponseType = EmptyResponse
    typealias ErrorType = AnyError
    
    var method: HTTP.Method = .delete
    var url: URL {
        return URL(string: "https://jsonplaceholder.typicode.com/posts/\(postId)")!
    }
    var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
    var body: Data?
    
    private let postId: Int
    
    init(postId: Int) {
        self.postId = postId
    }
}

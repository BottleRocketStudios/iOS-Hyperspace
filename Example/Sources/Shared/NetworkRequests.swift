//
//  Requests.swift
//  Example
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace

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
extension Request where Response == User {
    
    static func getUser(withID id: Int) -> Request<User> {
        return Request(url: URL(string: "https://jsonplaceholder.typicode.com/users/\(id)")!)
    }
}

// MARK: - Create Post Request
extension Request where Response == Post {
    
    static func createPost(_ post: NewPost) -> Request<Post> {
        return Request(method: .post, url: URL(string: "https://jsonplaceholder.typicode.com/posts")!, headers: [.contentType: .applicationJSON],
                       body: try? HTTP.Body.json(post))
    }
}

// MARK: - Delete Post Request
extension Request where Response == Void {
    
    static func deletePost(withID id: Int) -> Request<Void> {
        return Request.withEmptyResponse(method: .delete, url: URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!)
    }
}

//
//  Requests.swift
//  Hyperspace_Example
//
//  Created by Tyler Milner on 7/14/17.
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

extension Request where Response == User, Error == AnyError {
    
    static func getUser(withID id: Int) -> Request<User, AnyError> {
        return Request(method: .get, url: URL(string: "https://jsonplaceholder.typicode.com/users/\(id)")!)
    }
}

// MARK: - Create Post Request

extension Request where Response == Post, Error == AnyError {
    
    static func createPost(_ post: NewPost) -> Request<Post, AnyError> {
        return Request(method: .post, url: URL(string: "https://jsonplaceholder.typicode.com/posts")!, headers: [.contentType: .applicationJSON],
                       body: try? HTTP.Body(post))
    }
}

// MARK: - Delete Post Request

extension Request where Response == EmptyResponse, Error == AnyError {
    
    static func deletePost(withID id: Int) -> Request<EmptyResponse, AnyError> {
        return Request.withEmptyResponse(method: .delete, url: URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!)
    }
}

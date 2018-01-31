//
//  Models.swift
//  Hyperspace_Example
//
//  Created by Tyler Milner on 7/14/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

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

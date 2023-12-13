// : Playground - noun: a place where people can play

import UIKit
import Hyperspace

extension Request where Response == Void {

    static func deletePost(withID id: Int) -> Request<Void> {
        return Request.withEmptyResponse(method: .delete, url: URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!)
    }
}

let deletePostRequest = Request<EmptyResponse>.deletePost(withID: 1)
let backendService = BackendService()

do {
    try await backendService.execute(request: deletePostRequest)
    print("Deleted post successfully")
} catch {
    print("Error deleting post: \(error)")
}

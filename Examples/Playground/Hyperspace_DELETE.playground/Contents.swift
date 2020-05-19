//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import Hyperspace

PlaygroundPage.current.needsIndefiniteExecution = true

extension Request where Response == EmptyResponse, Error == AnyError {

    static func deletePost(withID id: Int) -> Request<EmptyResponse, AnyError> {
        return Request<EmptyResponse, AnyError>(method: .delete, url: URL(string: "http://jsonplaceholder.typicode.com/posts/\(id)")!) { success in
            return .success(EmptyResponse())
        }
    }
}

let deletePostRequest = Request<EmptyResponse, AnyError>.deletePost
let backendService = BackendService()

backendService.execute(request: deletePostRequest) { result in
    switch result {
    case .success:
        debugPrint("Deleted post successfully")
    case .failure(let error):
        debugPrint("Error deleting post: \(error)")
    }
    
    PlaygroundPage.current.finishExecution()
}

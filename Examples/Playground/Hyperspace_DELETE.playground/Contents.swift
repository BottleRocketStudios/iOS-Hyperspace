//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import Hyperspace
import Result

PlaygroundPage.current.needsIndefiniteExecution = true

struct DeletePostRequest: NetworkRequest {
    typealias ResponseType = EmptyResponse
    typealias ErrorType = AnyError
    
    var method: HTTP.Method = .delete
    var url: URL {
        return URL(string: "http://jsonplaceholder.typicode.com/posts/\(postId)")!
    }
    var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?
    var body: Data?

    private let postId: Int

    init(postId: Int) {
        self.postId = postId
    }
}

let deletePostRequest = DeletePostRequest(postId: 1)

// Alternatively, you can use the "AnyNetworkRequest" type to implement this simple DELETE request:

//let deletePostRequest = AnyNetworkRequest<EmptyResponse>(method: .delete, url: URL(string: "http://jsonplaceholder.typicode.com/posts/1")!) { (data) -> Result<EmptyResponse, AnyError> in
//    return .success(EmptyResponse())
//}

let backendService = BackendService()

backendService.execute(request: deletePostRequest) { (result) in
    switch result {
    case .success:
        debugPrint("Deleted post successfully")
    case .failure(let error):
        debugPrint("Error deleting post: \(error)")
    }
    
    PlaygroundPage.current.finishExecution()
}

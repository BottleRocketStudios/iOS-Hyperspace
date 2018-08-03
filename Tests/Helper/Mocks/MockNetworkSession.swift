//
//  MockNetworkSession.swift
//  HyperspaceTests
//
//  Created by Tyler Milner on 6/28/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Hyperspace

class MockNetworkSession {
    
    private let responseStatusCode: Int?
    private let responseData: Data?
    private let error: Error?
    var nextDataTask: NetworkSessionDataTask = MockNetworkSessionDataTask(request: URLRequest(url: RequestTestDefaults.defaultURL))
    
    init(responseStatusCode: Int?, responseData: Data?, error: Error?) {
        self.responseStatusCode = responseStatusCode
        self.responseData = responseData
        self.error = error
    }
}

extension MockNetworkSession: NetworkSession {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkSessionDataTask {
        guard let url = request.url else { fatalError("No \(URL.self) provided") }
        
        let response: HTTPURLResponse? = responseStatusCode.flatMap { HTTPURLResponse(url: url, statusCode: $0, httpVersion: "HTTP/1.1", headerFields: nil) }
        
        DispatchQueue.global().async {
            completionHandler(self.responseData, response, self.error)
        }
        
        return nextDataTask
    }
}

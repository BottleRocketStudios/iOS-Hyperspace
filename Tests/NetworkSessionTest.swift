//
//  NetworkSessionTest.swift
//  HyperspaceTests
//
//  Created by Adam Brzozowski on 1/29/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import XCTest
import Hyperspace

class NetworkSessionTest: XCTestCase {
    
    // MARK: - Properties
    
    private let defaultRequest = URLRequest(url: RequestTestDefaults.defaultURL)
    
    // MARK: - Tests
    
    func test_URLSessionNetworkSessionImplementation_ReturnsURLSessionDataTask() {
        let networkSession: TransportSession = URLSession.shared
        let networkSessionDataTask: TransportDataTask = networkSession.dataTask(with: defaultRequest, completionHandler: { _, _, _ in })

        XCTAssert(networkSessionDataTask is URLSessionDataTask)
    }
}

////
////  TransportSessionTests.swift
////  Tests
////
////  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
////
//
//import XCTest
//import Hyperspace
//
//class TransportSessionTests: XCTestCase {
//    
//    // MARK: - Properties
//    
//    private let defaultRequest = URLRequest(url: RequestTestDefaults.defaultURL)
//    
//    // MARK: - Tests
//    
//    func test_URLSessionTransportSessionImplementation_ReturnsURLSessionDataTask() {
//        let networkSession: TransportSession = URLSession.shared
//        let networkSessionDataTask: TransportDataTask = networkSession.dataTask(with: defaultRequest, completionHandler: { _, _, _ in })
//
//        XCTAssert(networkSessionDataTask is URLSessionDataTask)
//    }
//}

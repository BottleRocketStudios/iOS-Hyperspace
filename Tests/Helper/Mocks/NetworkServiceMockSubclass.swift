//
//  NetworkServiceMockSubclass.swift
//  Hyperspace
//
//  Created by Adam Brzozowski on 1/31/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation
@testable import Hyperspace

class NetworkServiceMockSubclass: NetworkService {
    
    private(set) var initWithNetworkActivityControllerCalled = false
    
    override init(session: NetworkSession, networkActivityController: NetworkActivityController?) {
        initWithNetworkActivityControllerCalled = true
        super.init(session: session, networkActivityController: networkActivityController)
    }
}

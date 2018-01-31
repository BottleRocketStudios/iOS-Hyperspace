//
//  MockNetworkService2.swift
//  Hyperspace-iOS
//
//  Created by Adam Brzozowski on 1/31/18.
//  Copyright © 2018 Bottle Rocket Studios. All rights reserved.
//

import Foundation


class MockNetworkService2: NetworkService {
    var setup = false
    
    override init(session: NetworkSession, networkActivityController: NetworkActivityController?) {
        setup = true
        super.init(session: session, networkActivityController: networkActivityController)
    }
}

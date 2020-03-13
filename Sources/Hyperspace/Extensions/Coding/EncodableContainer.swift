//
//  EncodableContainer.swift
//  Hyperspace
//
//  Created by William McGinty on 3/7/20.
//  Copyright © 2020 Bottle Rocket Studios. All rights reserved.
//

import Foundation

// Represents something that is capable of Encoding itself (using `Swift.Encodable`) and contains a child type.
public protocol EncodableContainer: Encodable {
    
    /// The type of the `Swift.Encodable` child element.
    associatedtype Contained: Encodable
    
    /// Initializes a new instance of the container.
    /// - Parameter element: The element to be placed inside the container.
    init(element: Contained)
    
    /// Retrieve the child type from its container.
    var element: Contained { get }
}

//
//  Cancellation.swift
//  Hyperspace-iOS
//
//  Created by Will McGinty on 2/19/19.
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// Manages cancellation tokens and signals them when cancellation is requested.
///
/// All `CancellationTokenSource` methods are thread safe.
public final class CancellationSource {
    
    public struct Token {
        // MARK: Properties
        private weak var source: CancellationSource?
        public var isCancelling: Bool { return source?.isCancelling ?? false }
        
        public init(source: CancellationSource?) {
            self.source = source
        }
        
        // MARK: Interface
        public func register(closure: @escaping () -> Void) {
            source?.register(closure)
        }
    }
    
    // MARK: Properties
    private let lock = NSLock()
    private var observers: [() -> Void]? = []
    
    // MARK: Initializers
    public init() {}
    
    // MARK: Interface
    public var isCancelling: Bool {
        lock.lock()
        defer { lock.unlock() }
        return observers == nil
    }
    
    public var token: CancellationSource.Token { return CancellationSource.Token(source: self) }
    
    // MARK: Registration
    fileprivate func register(_ handler: @escaping () -> Void) {
        if !lockedRegister(handler) {
            handler()
        }
    }
    
    private func lockedRegister(_ handler: @escaping () -> Void) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        observers?.append(handler)
        return observers != nil
    }
    
    // MARK: Cancellation
    public func cancel() {
        if let observers = lockedCancel() {
            observers.forEach { $0() }
        }
    }
    
    private func lockedCancel() -> [() -> Void]? {
        lock.lock()
        defer { lock.unlock() }
        
        let observers = self.observers
        self.observers = nil //Transition to `isCancelling`
        
        return observers
    }
}

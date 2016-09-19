//
//  Subscriber.swift
//  CirrusMD
//
//  Created by David Nix on 3/28/16.
//  Copyright © 2016 CirrusMD. All rights reserved.

//  Attribution:
//  Created by Virgilio Favero Neto on 4/02/2016.
//  Copyright © 2016 Benjamin Encz. All rights reserved.
//  https://github.com/ReSwift/ReSwift
//

internal struct GenericSubscription<State> {
    typealias ScopeFunc = (State) -> Any
    private(set) weak var subscriber: SubscriberType?
    let scope: ScopeFunc?
    
    init(subscriber: SubscriberType, scope: ScopeFunc?) {
        self.subscriber = subscriber
        self.scope = scope
    }
}

// Must be a class because it may be a weak reference
public protocol SubscriberType: class {
    func _updateState(previous: Any?, current: Any)
}


public protocol Subscriber: SubscriberType {
    associatedtype State

    func updateState(previous: State?, current: State)
}

extension Subscriber {
    public func _updateState(previous: Any?, current: Any) {
        let previous = previous as? State
        if let current = current as? State {
            updateState(previous, current: current)
        } else {
            assertionFailure("Redux subscriber \(self) received unexpected state \(current)")
        }
    }
}
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
    fileprivate(set) weak var subscriber: AnySubscriber?
    let scope: ScopeFunc?

    init(subscriber: AnySubscriber, scope: ScopeFunc?) {
        self.subscriber = subscriber
        self.scope = scope
    }
}

// Must be a class because it may be a weak reference
public protocol AnySubscriber: class {
    func _updateState(previous: Any?, current: Any)
}


public protocol Subscriber: AnySubscriber {
    associatedtype State

    func updateState(previous: State?, current: State)
}

extension Subscriber {
    public func _updateState(previous: Any?, current: Any) {
        let previous = previous as? State
        if let current = current as? State {
            updateState(previous: previous, current: current)
        } else {
            assertionFailure("[UDF] Subscriber \(self) received unexpected state \(current)")
        }
    }
}

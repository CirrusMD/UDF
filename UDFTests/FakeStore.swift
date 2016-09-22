//
//  FakeStore.swift
//  CirrusMD
//
//  Created by David Nix on 1/21/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

import UDF


class FakeStore<State, RD: Reducer>: Store<State, RD> where RD.State == State {

    var lastActions: [Action] = []
    var lastAction: Action? {
        return lastActions.last
    }
    var lastDispatchers: [Dispatcher] = []
    var subscribers: [SubscriberType] = []
    var state: State

    func reset() {
        lastActions = []
        lastDispatchers = []
        subscribers = []
    }

    override init(reducer: RD, initialState: State) {
        self.state = initialState
        super.init(reducer: reducer, initialState: initialState)
    }

    override func currentState() -> State {
        return state
    }

    override func dispatch(_ action: Action) {
        lastActions.append(action)
    }

    override func dispatch(_ actionDispatcher: Dispatcher) {
        lastDispatchers.append(actionDispatcher)
    }

    override func subscribe<ScopedState, S: Subscriber>(_ subscriber: S, scope: ((State) -> ScopedState)?) where S.State == ScopedState {
        subscribers.append(subscriber)
    }

    override func subscribe<S: Subscriber>(_ subscriber: S) where S.State == State {
        subscribers.append(subscriber)
    }

    override func unSubscribe(_ subscriber: AnyObject) {
        if let index = subscribers.index(where: { return $0 === subscriber }) {
            subscribers.remove(at: index)
        }
    }
}


class ActionCollector {
    var lastActions: [Action] = []

    func dispatch(action: Action) {
        lastActions.append(action)
    }
}

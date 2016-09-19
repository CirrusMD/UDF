//
//  FakeStore.swift
//  CirrusMD
//
//  Created by David Nix on 1/21/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

import UniFlow


class FakeStore<State, RD: Reducer where RD.State == State>: Store<State, RD> {
    
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
    
    override func dispatch(action: Action) {
        lastActions.append(action)
    }
    
    override func dispatch(actionDispatcher: Dispatcher) {
        lastDispatchers.append(actionDispatcher)
    }
    
    override func subscribe<ScopedState, S :Subscriber where S.State == ScopedState>(subscriber: S, scope: (State -> ScopedState)?) {
        subscribers.append(subscriber)
    }
    
    override func subscribe<S :Subscriber where S.State == State>(subscriber: S) {
        subscribers.append(subscriber)
    }
    
    override func unSubscribe(subscriber: AnyObject) {
        if let index = subscribers.indexOf({ return $0 === subscriber }) {
            subscribers.removeAtIndex(index)
        }
    }
}


class ActionCollector {
    var lastActions: [Action] = []
    
    func dispatch(action: Action) {
        lastActions.append(action)
    }
}

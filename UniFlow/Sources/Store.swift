//
//  Store.swift
//  CirrusMD
//
//  Created by David Nix on 1/20/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//
//  Attribution:
//  Created by Benjamin Encz on 11/11/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//  https://github.com/ReSwift/ReSwift
//


public class Store<State, RD: Reducer where RD.State == State> {

    public typealias Dispatcher = ActionDispatcher<State>
    
    private typealias Subscription = GenericSubscription<State>

    private var previousState: State?
    private var state: State
    
    private let reducer: RD
    private var subscriptions: [Subscription] = []

    public init(reducer: RD, initialState: State) {
        self.reducer = reducer
        self.state = initialState
    }

    public func currentState() -> State {
        var current: State!
        let sem = dispatch_semaphore_create(0)
        sync {
            current = self.state
            dispatch_semaphore_signal(sem)
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
        return current
    }

    public func dispatch(action: Action) {
        _dispatch(action)
    }

    public func dispatch(actionDispatcher: Dispatcher) {
        actionDispatcher.dispatch(currentState, _dispatch)
    }

    private func _dispatch(action: Action) {
        sync {
            debugLog("DISPATCHED ACTION: \(action)")
            self.previousState = self.state
            let newState = self.reducer.handleAction(action, forState: self.state)
            self.state = newState
            
            if let prev = self.previousState {
                debugLog(debugDiff(prev, rhs: self.state))
            } else {
                debugLog(debugDiff("", rhs: self.state))
            }
            
            self.informSubscribers(self.previousState, current: newState)
        }
    }
    
    public func subscribe<ScopedState, S:Subscriber where S.State == ScopedState>
        (subscriber: S, scope: (State -> ScopedState)?) {
        sync {
            if self.subscriptions.contains({ $0.subscriber === subscriber }) {
                debugLog("\(#file): \(#function): subscriber \(subscriber) is already registered, ignoring.")
                return
            }
            let subscription = Subscription(subscriber: subscriber, scope: scope)
            self.subscriptions.append(subscription)
            self.informSubscriber(subscription, previous: self.previousState, current: self.state)
        }
    }

    public func subscribe<S:Subscriber where S.State == State>(subscriber: S) {
        subscribe(subscriber, scope: nil)
    }

    public func unSubscribe(subscriber: AnyObject) {
        weak var weakSubscriber = subscriber
        sync {
            if let subscriber = weakSubscriber, let index = self.subscriptions.indexOf({ $0.subscriber === subscriber }) {
                self.subscriptions.removeAtIndex(index)
            }
        }
    }

    private let actionQueue = dispatch_queue_create("com.cirrusmd.reduxStore.action", DISPATCH_QUEUE_SERIAL)
    private let deadlockQueue = dispatch_queue_create(
        "com.cirrusmd.reduxStore.deadlockMonitoring",
        DISPATCH_QUEUE_CONCURRENT
    )
    private func sync(block: () -> Void) {
        let sem = dispatch_semaphore_create(0)
        let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * NSEC_PER_SEC))
        
        dispatch_async(actionQueue) {
            block()
            dispatch_semaphore_signal(sem)
        }
        
        dispatch_async(deadlockQueue) {
            if dispatch_semaphore_wait(sem, timeout) != 0 {
                fatalError("ReduxStore deadlock timeout. Did a reducer dispatch an action?")
            }
        }
    }

    private func informSubscribers(previous: State?, current: State) {
        let valid = subscriptions.filter {
            return $0.subscriber != nil
        }
        
        valid.forEach {
            self.informSubscriber($0, previous: self.previousState, current: self.state)
        }
        
        subscriptions = valid
    }

    private func informSubscriber(subscription: Subscription, previous: State?, current: State) {
        scheduleOnNextRunLoop {
            var prev: Any? = nil
            if let previous = previous {
                prev = subscription.scope?(previous) ?? previous
            }
            let curr = subscription.scope?(current) ?? current
            subscription.subscriber?._updateState(prev, current: curr)
        }
    }
}

private func debugLog(message: String) {
    #if DEBUG
        print(#file, "[DEBUG]", message)
    #endif
}


private func scheduleOnNextRunLoop(block: () -> Void) {
    dispatch_async(dispatch_get_main_queue(), block)
}
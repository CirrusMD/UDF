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
import Dispatch


open class Store<State, RD: Reducer> where RD.State == State {

    public typealias Dispatcher = ActionDispatcher<State>

    fileprivate typealias Subscription = GenericSubscription<State>
    
    fileprivate var previousState: State?
    fileprivate var state: State
    fileprivate var isDispatching = false

    fileprivate let reducer: RD
    fileprivate var subscriptions: [Subscription] = []
    fileprivate let config: Config

    public init(reducer: RD, initialState: State, config: Config = Config.default) {
        self.reducer = reducer
        self.state = initialState
        self.config = config
    }

    open func currentState() -> State {
        if Thread.isMainThread {
            return self.state
        }
        
        var current: State!
        let sem = DispatchSemaphore(value: 0)
        scheduleOnNextRunLoop {
            current = self.state
            sem.signal()
        }
        _ = sem.wait(timeout: DispatchTime.distantFuture)
        return current
    }

    open func dispatch(_ action: Action) {
        _dispatch(action: action)
    }

    open func dispatch(_ actionDispatcher: Dispatcher) {
        actionDispatcher.dispatch(currentState, _dispatch)
    }

    fileprivate func _dispatch(action: Action) {
        sync {
            guard !self.isDispatching else {
                fatalError("[UDF]: Deadlock detected. Did a reducer dispatch an action or a subscriber dispatch while updating state?")
            }
            self.isDispatching = true
            self.logDebug("DISPATCHED ACTION: \(action)")
            
            let start = Date()
            self.previousState = self.state
            let newState = self.reducer.handle(action: action, forState: self.state)
            self.state = newState
            self.logElapsedTime(start: start)

            if let prev = self.previousState {
                self.logDebug(debugDiff(lhs: prev, rhs: self.state))
            } else {
                self.logDebug(debugDiff(lhs: "", rhs: self.state))
            }

            self.informSubscribers(self.previousState, current: newState)
            self.isDispatching = false
        }
    }

    open func subscribe<ScopedState, S: Subscriber>
        (_ subscriber: S, scope: ((State) -> ScopedState)?) where S.State == ScopedState {
        sync {
            if self.subscriptions.contains(where: { $0.subscriber === subscriber }) {
                self.logDebug("\(#file): \(#function): subscriber \(subscriber) is already registered, ignoring.")
                return
            }
            let subscription = Subscription(subscriber: subscriber, scope: scope)
            self.subscriptions.append(subscription)
            self.informSubscriber(subscription, previous: self.previousState, current: self.state)
        }
    }

    open func subscribe<S: Subscriber>(_ subscriber: S) where S.State == State {
        subscribe(subscriber, scope: nil)
    }

    open func unSubscribe(_ subscriber: AnyObject) {
        sync {
            if let index = self.subscriptions.index(where: { $0.subscriber === subscriber }) {
                self.subscriptions.remove(at: index)
            }
        }
    }

    fileprivate func sync(_ closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            scheduleOnNextRunLoop(closure)
        }
    }

    fileprivate func informSubscribers(_ previous: State?, current: State) {
        let valid = subscriptions.filter { $0.subscriber != nil }

        valid.forEach {
            self.informSubscriber($0, previous: self.previousState, current: self.state)
        }

        subscriptions = valid
    }

    fileprivate func informSubscriber(_ subscription: Subscription, previous: State?, current: State) {
        var prev: Any? = nil
        if let previous = previous {
            prev = subscription.scope?(previous) ?? previous
        }
        let curr = subscription.scope?(current) ?? current
        subscription.subscriber?._updateState(previous: prev, current: curr)
    }
}

private extension Store {
    
    func logDebug(_ message: String) {
        if config.debug {
            print("[UDF: DEBUG]", message)
        }
    }
    
    func logElapsedTime(start: Date) {
        guard config.debug else {
            return
        }
        let duration = abs(start.timeIntervalSinceNow) * 1_000_000
        let formatted = formatter.string(from: NSNumber(value: duration)) ?? "unknown"
        logDebug("Time spent reducing state: \(formatted) μs")
    }
}

private func scheduleOnNextRunLoop(_ block: @escaping () -> Void) {
    DispatchQueue.main.async(execute: block)
}

private let formatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.locale = NSLocale.current
    f.alwaysShowsDecimalSeparator = true
    f.minimumFractionDigits = 2
    f.maximumFractionDigits = 2
    f.groupingSeparator = ","
    f.usesGroupingSeparator = true
    return f
}()

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

    fileprivate let reducer: RD
    fileprivate var subscriptions: [Subscription] = []
    fileprivate let config: Config

    public init(reducer: RD, initialState: State, config: Config = Config.default) {
        self.reducer = reducer
        self.state = initialState
        self.config = config
    }

    open func currentState() -> State {
        var current: State!
        let sem = DispatchSemaphore(value: 0)
        sync {
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
            self.logDebug("DISPATCHED ACTION: \(action)")
            
            let reduceStart = Date()
            self.previousState = self.state
            let newState = self.reducer.handle(action: action, forState: self.state)
            self.state = newState
            self.logElapsedTime(start: reduceStart, message: "Reducer elapsed time")

            if let prev = self.previousState {
                self.logDebug(debugDiff(lhs: prev, rhs: self.state))
            } else {
                self.logDebug(debugDiff(lhs: "", rhs: self.state))
            }

            let subscribeStart = Date()
            self.informSubscribers(self.previousState, current: newState)
            self.logElapsedTime(start: subscribeStart, message: "Subscriber elapsed time")
        }
    }

    open func subscribe<ScopedState, S: Subscriber>
        (_ subscriber: S, scope: ((State) -> ScopedState)?) where S.State == ScopedState {
        sync {
            if self.subscriptions.contains(where: { $0.subscriber === subscriber }) {
                self.logDebug("subscriber \(subscriber) is already registered, ignoring.")
                return
            }
            let subscription = Subscription(subscriber: subscriber, scope: scope)
            self.logDebug("adding subscriber \(subscription)")
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
                self.logDebug("removing subscriber \(self.subscriptions[index])")
                self.subscriptions.remove(at: index)
            }
        }
    }

    fileprivate let actionQueue = DispatchQueue(label: "com.cirrusmd.reduxStore.action", attributes: [])
    fileprivate let deadlockQueue = DispatchQueue(
        label: "com.cirrusmd.reduxStore.deadlockMonitoring",
        attributes: DispatchQueue.Attributes.concurrent
    )
    fileprivate func sync(_ block: @escaping () -> Void) {
        let sem = DispatchSemaphore(value: 0)
        let timeout = DispatchTime.now() + Double(Int64(10 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        actionQueue.async {

            block()
            sem.signal()
        }

        deadlockQueue.async {
            if sem.wait(timeout: timeout) == .timedOut {
                fatalError("ReduxStore deadlock timeout. Did a reducer dispatch an action?")
            }
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
    
    func logElapsedTime(start: Date, message: String) {
        guard config.debug else {
            return
        }
        let duration = abs(start.timeIntervalSinceNow) * 1_000_000
        let formatted = formatter.string(from: NSNumber(value: duration)) ?? "unknown"
        logDebug("\(message): \(formatted) μs")
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

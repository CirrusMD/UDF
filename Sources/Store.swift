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
    private typealias Subscription = GenericSubscription<State>
    
    private var previousState: State?
    private var state: State

    private let reducer: RD
    private var subscriptions: [Subscription] = []
    fileprivate let config: Config
    
    let group = DispatchGroup()
    
    private let reducerQueue = DispatchQueue(
        label: "com.cirrusmd.UDF.reducerQueue",
        attributes: [.concurrent]
    )
    private let deadlockQueue = DispatchQueue(
        label: "com.cirrusmd.UDF.deadlockMonitoring",
        attributes: [.concurrent]
    )
    private let mainQueue = DispatchQueue.main

    public init(reducer: RD, initialState: State, config: Config = Config.default) {
        self.reducer = reducer
        self.state = initialState
        self.config = config
    }

    open func currentState() -> State {
        if group.wait(timeout: DispatchTime.now() + .seconds(10)) == .timedOut {
            fatalError("deadlock")
        }
        return reducerQueue.sync { self.state }
    }
    
    open func dispatch(_ actionDispatcher: Dispatcher) {
        actionDispatcher.dispatch(currentState, dispatch)
    }

    open func dispatch(_ action: Action) {
        sync { self._dispatch(action: action) }
    }

    private func _dispatch(action: Action) {
        if group.wait(timeout: DispatchTime.now() + .seconds(10)) == .timedOut {
            fatalError("deadlock")
        }
        
        logDebug("DISPATCHED ACTION: \(action)")
        
        let reduceStart = Date()
        previousState = state
        let newState = reducer.handle(action: action, forState: state)
        state = newState
        logElapsedTime(start: reduceStart, message: "Reducer elapsed time")

        if let prev = previousState {
            logDebug(debugDiff(lhs: prev, rhs: state))
        } else {
            logDebug(debugDiff(lhs: "", rhs: state))
        }

        let subscribeStart = Date()
        let valid = subscriptions.filter { $0.subscriber != nil }
        
        group.enter()
        mainQueue.async {
            valid.forEach {
                self.informSubscriber($0, previous: self.previousState, current: self.state)
            }
            self.group.leave()
        }
        subscriptions = valid
        logElapsedTime(start: subscribeStart, message: "Subscriber elapsed time")
    }

    open func subscribe<S: Subscriber>(_ subscriber: S) where S.State == State {
        subscribe(subscriber, scope: nil)
    }

    open func subscribe<ScopedState, S: Subscriber>
        (_ subscriber: S, scope: ((State) -> ScopedState)?) where S.State == ScopedState {
        sync {
            self._subscribe(subscriber, scope: scope)
        }
    }
    
    private func _subscribe<ScopedState, S: Subscriber>
        (_ subscriber: S, scope: ((State) -> ScopedState)?) where S.State == ScopedState {
        if subscriptions.contains(where: { $0.subscriber === subscriber }) {
            logDebug("subscriber \(subscriber) is already registered, ignoring.")
            return
        }
        let subscription = Subscription(subscriber: subscriber, scope: scope)
        logDebug("adding subscriber \(subscription)")
        subscriptions.append(subscription)
        
        group.enter()
        mainQueue.async {
            self.informSubscriber(subscription, previous: self.previousState, current: self.state)
            self.group.leave()
        }
    }
    
    open func unSubscribe(_ subscriber: AnyObject) {
        sync {
            if let index = self.subscriptions.index(where: { $0.subscriber === subscriber }) {
                self.logDebug("removing subscriber \(self.subscriptions[index])")
                self.subscriptions.remove(at: index)
            }
        }
    }
    
    private func sync(_ block: @escaping () -> Void) {
//        let sem = DispatchSemaphore(value: 0)
//        let timeout = DispatchTime.now() + .seconds(10)
        reducerQueue.async(flags: .barrier) {
            block()
//            sem.signal()
        }

//        deadlockQueue.async {
//            if sem.wait(timeout: timeout) == .timedOut {
//                fatalError("[UDF]: Store deadlock timeout. Did a reducer dispatch an action?")
//            }
//        }
    }
    
    private func informSubscriber(_ subscription: Subscription, previous: State?, current: State) {
        var prev: Any? = nil
        if let previous = previous {
            prev = subscription.scope?(previous) ?? previous
        }
        let curr = subscription.scope?(current) ?? current
        subscription.subscriber?._updateState(previous: prev, current: curr)
    }
}

private extension Store {
    
}

// MARK: Debug 
private extension Store {
    
    func logDebug(_ message: String) {
        if config.debug {
            print("[UDF DEBUG] \(self):", message)
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

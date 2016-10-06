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
    
    private var previousState: State?
    private var state: State

    private let reducer: RD
    private var subscriptions: [Subscription] = []
    fileprivate let config: Config
    
    fileprivate let reducerQueue = DispatchQueue(
        label: "com.cirrusmd.UDF.reducerQueue",
        attributes: [.concurrent]
    )

    public init(reducer: RD, initialState: State, config: Config = Config.default) {
        self.reducer = reducer
        self.state = initialState
        self.config = config
    }

    open func currentState() -> State {
        var currentState: State!
        let sem = DispatchSemaphore(value: 0)
        read {
            currentState = self.state
            sem.signal()
        }
        if sem.wait(timeout: DispatchTime.now() + .seconds(10)) == .timedOut {
            fatalError("deadlock")
        }
        return currentState
    }
    
    open func dispatch(_ actionDispatcher: Dispatcher) {
        actionDispatcher.dispatch(currentState, dispatch)
    }

    open func dispatch(_ action: Action) {
        sync {
            self.logDebug("RECEIVED ACTION: \(action)")
            self.reduceState(forAction: action)
            self.cleanSubscriptions()
            return self.subscriptions
        }
    }
    
    open func subscribe<S: Subscriber>(_ subscriber: S) where S.State == State {
        subscribe(subscriber, scope: nil)
    }

    open func subscribe<ScopedState, S: Subscriber>
        (_ subscriber: S, scope: ((State) -> ScopedState)?) where S.State == ScopedState {
        sync {
            if self.subscriptions.contains(where: { $0.subscriber === subscriber }) {
                self.logDebug("subscriber \(subscriber) is already registered, ignoring.")
                return []
            }
            let subscription = Subscription(subscriber: subscriber, scope: scope)
            self.logDebug("adding subscriber \(subscription)")
            self.subscriptions.append(subscription)
            return [subscription]
        }
    }
    
    open func unSubscribe(_ subscriber: AnyObject) {
        write {
            if let index = self.subscriptions.index(where: { $0.subscriber === subscriber }) {
                self.logDebug("removing subscriber \(self.subscriptions[index])")
                self.subscriptions.remove(at: index)
            }
        }
    }
    
    private func reduceState(forAction action: Action) {
        let reduceStart = Date()
        previousState = state
        let newState = reducer.handle(action: action, forState: state)
        state = newState
        logElapsedTime(start: reduceStart, message: "Reducer elapsed time")

        logDebug(debugDiff(lhs: previousState ?? "", rhs: state))
    }
    
    private func cleanSubscriptions() {
        subscriptions = subscriptions.filter { $0.subscriber != nil }
    }
    
    fileprivate func informSubscriber(_ subscription: Subscription) {
        var prev: Any? = nil
        if let previous = previousState {
            prev = subscription.scope?(previous) ?? previous
        }
        let curr = subscription.scope?(state) ?? state
        subscription.subscriber?._updateState(previous: prev, current: curr)
    }
}

// MARK: Synchronization
private extension Store {
    func read(_ operation: @escaping () -> Void) {
        reducerQueue.async(execute: operation)
    }
    
    func write(_ operation: @escaping () -> Void) {
        reducerQueue.async(flags: .barrier, execute: operation)
    }
    
    func sync(writeOperation: @escaping () -> [Subscription]) {
        write {
            let subscriptions = writeOperation()
            guard subscriptions.count > 0 else {
                self.logDebug("No subcribers; Skipping updateState for current Action")
                return
            }
            let sem = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                let start = Date()
                subscriptions.forEach { self.informSubscriber($0) }
                self.logElapsedTime(start: start, message: "Subscriber elapsed time")
                sem.signal()
            }
            _ = sem.wait()
        }
    }
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

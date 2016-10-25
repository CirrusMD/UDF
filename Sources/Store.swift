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
    public typealias GetState = () -> State
    public typealias Middleware = (@escaping GetState) -> (@escaping DispatchFunc) -> DispatchFunc

    private typealias Subscription = GenericSubscription<State>
    
    private var previousState: State?
    private var state: State

    fileprivate let config: Config
    private let reducer: RD
    private var subscriptions: [Subscription] = []
    private lazy var mainDispatch: DispatchFunc = { _ in }
    private let actionQueue = DispatchQueue(label: "com.cirrusmd.udf.action", attributes: [.concurrent])

    public init(reducer: RD, initialState: State, middleware: [Middleware] = [], config: Config = Config.default) {
        self.reducer = reducer
        self.state = initialState
        self.config = config
        let debugMiddleware = config.debug ? [StateDiffLogger, DebugLogger] + middleware : middleware
        self.mainDispatch = debugMiddleware
            .reversed()
            .reduce(_reduceState, { [unowned self] (dispatch, middleware) -> DispatchFunc in
                return middleware({ self.state })(dispatch)
            })
    }
    
    open func currentState() -> State {
        var current: State!
        let sem = DispatchSemaphore(value: 0)
        actionQueue.async { [unowned self] in
            current = self.state
            sem.signal()
        }
        if sem.wait(timeout: DispatchTime.now() + .seconds(10)) == .timedOut {
            preconditionFailure("[UDF] Store \(self) timeout detected. Was there a deadlock?")
        }
        return current
    }

    open func dispatch(_ action: Action) {
        _dispatch(action: action)
    }

    open func dispatch(_ actionDispatcher: Dispatcher) {
        actionDispatcher.dispatch(currentState, _dispatch)
    }

    private func _dispatch(action: Action) {
        sync { [unowned self] in
            self.mainDispatch(action)
        }
    }
    
    private func _reduceState(action: Action) {
        self.previousState = self.state
        let newState = self.reducer.handle(action: action, forState: self.state)
        self.state = newState
        self.informSubscribers(self.previousState, current: newState)
    }

    open func subscribe<ScopedState, S: Subscriber>
        (_ subscriber: S, scope: ((State) -> ScopedState)?) where S.State == ScopedState {
        sync { [unowned self] in
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
        weak var weakSubscriber = subscriber
        sync { [unowned self] in
            if let subscriber = weakSubscriber, let index = self.subscriptions.index(where: { $0.subscriber === subscriber }) {
                self.subscriptions.remove(at: index)
            }
        }
    }

    private func sync(_ block: @escaping () -> Void) {
        actionQueue.async(flags: .barrier, execute: block)
    }

    private func informSubscribers(_ previous: State?, current: State) {
        let valid = subscriptions.filter {
            return $0.subscriber != nil
        }

        valid.forEach {
            informSubscriber($0, previous: self.previousState, current: self.state)
        }

        subscriptions = valid
    }

    private func informSubscriber(_ subscription: Subscription, previous: State?, current: State) {
        scheduleOnNextRunLoop {
            var prev: Any? = nil
            if let previous = previous {
                prev = subscription.scope?(previous) ?? previous
            }
            let curr = subscription.scope?(current) ?? current
            subscription.subscriber?._updateState(previous: prev, current: curr)
        }
    }
}

private extension Store {
    
    func logDebug(_ message: String) {
        if config.debug {
            print("[UDF: DEBUG]", message)
        }
    }
}

private func scheduleOnNextRunLoop(_ block: @escaping () -> Void) {
    DispatchQueue.main.async(execute: block)
}

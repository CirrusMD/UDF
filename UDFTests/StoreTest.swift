//
//  StoreTest.swift
//  CirrusMD
//
//  Created by David Nix on 1/20/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

import XCTest
import UDF


enum CountAction: Action {
    case Increment, Decrement
}


struct CounterState {
    var counter = 0
    var scopedState = ScopedState()
}


class TestReducer: Reducer {
    typealias State = CounterState

    var didHandleAction = false
    var state: CounterState?
    var expectation: XCTestExpectation?

    func handle(action: Action, forState state: CounterState) -> CounterState {
        var state = state
        guard let countAction = action as? CountAction else {
            return state
        }

        switch countAction {
        case .Increment:
            state.counter += 1
        case .Decrement:
            state.counter -= 1
        }

        state.scopedState.message = "Reducer did its job!"

        didHandleAction = true
        self.state = state
        expectation?.fulfill()
        return state
    }
}


class TestSubscriber: UIViewController, Subscriber {
    typealias State = CounterState

    var lastStates: [CounterState] = []
    var previousStates: [CounterState?] = []
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

    var expectation: XCTestExpectation?

    func updateState(previous: CounterState?, current: CounterState) {
        previousStates.append(previous)
        lastStates.append(current)
        label.text = "\(current.counter)"
        expectation?.fulfill()
    }

    override func loadView() {
        view = UIView()
        view.addSubview(label)
    }
}


struct ScopedState {
    var message = "Beginning Message"
}


private class FilteredSubscriber: Subscriber {
    typealias State = ScopedState
    var previousMessage = ""
    var message = ""
    var expectation: XCTestExpectation?

    func updateState(previous: State?, current: State) {
        previousMessage = previous?.message ?? ""
        message = current.message
        expectation?.fulfill()
    }
}


class ReduxStoreTest: XCTestCase {

    typealias TestReduxStore = Store<CounterState, TestReducer>
    let reducer = TestReducer()
    lazy var store: TestReduxStore = {
        return Store(reducer: self.reducer, initialState: CounterState(), config: Config(debug: false))
    }()
    
    func test_currentState() {
        store.dispatch(CountAction.Increment)
        
        XCTAssertEqual(store.currentState().counter, 1)

        let exp = expectation(description: "")
        var backgroundState: CounterState?
        scheduleInBackground {
            self.store.dispatch(CountAction.Increment)
            backgroundState = self.store.currentState()
            exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertEqual(backgroundState?.counter, 2)
    }

    func test_dispatch_action() {
        reducer.expectation = expectation(description: #function)
        store.dispatch(CountAction.Increment)
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(reducer.didHandleAction)
        XCTAssertEqual(reducer.state?.counter, 1)
    }

    func test_dispatch_actionCreator() {
        reducer.expectation = expectation(description: #function)
        let creator = ActionDispatcher<CounterState> { state, dispatch in
            dispatch(CountAction.Increment)
        }
        store.dispatch(creator)
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(reducer.didHandleAction)
        XCTAssertEqual(reducer.state?.counter, 1)
    }

    func test_subscribe() {
        let subscriber = TestSubscriber()
        subscriber.expectation = expectation(description: #function)
        store.subscribe(subscriber)
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(subscriber.lastStates.count, 1)
        XCTAssertEqual(subscriber.lastStates.last?.counter, 0)

        XCTAssertEqual(subscriber.previousStates.count, 1)
        if let item = subscriber.previousStates.last,
           let state = item {
            XCTFail("expected nil state, got \(state)")
        }

        subscriber.expectation = expectation(description: #function)
        store.dispatch(CountAction.Increment)
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(subscriber.lastStates.count, 2)
        XCTAssertEqual(subscriber.lastStates.last?.counter, 1)
        XCTAssertEqual(subscriber.previousStates.count, 2)

        if let item = subscriber.previousStates.last,
           let state = item {
            XCTAssertEqual(state.counter, 0)
        } else {
            XCTFail("expected previous state, got \(subscriber.previousStates.last)")
        }
    }

    func test_subscribe_toScopedState() {
        var state = CounterState()
        state.scopedState.message = "First Message"
        store = Store(reducer: reducer, initialState: state)

        let subscriber = FilteredSubscriber()
        subscriber.expectation = expectation(description: #function)

        store.subscribe(subscriber) { parentState in
            return parentState.scopedState
        }
        waitForExpectations(timeout: 1, handler: nil)

        subscriber.expectation = expectation(description: #function)
        store.dispatch(CountAction.Decrement)
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(subscriber.message, "Reducer did its job!")
        XCTAssertEqual(subscriber.previousMessage, "First Message")
    }

    func test_subscribe_ignoresDuplicates() {
        let subscriber = TestSubscriber()
        store.subscribe(subscriber) // 1
        store.subscribe(subscriber) // 2
        store.dispatch(CountAction.Increment) // 3, 4

        XCTAssertNotEqual(subscriber.lastStates.count, 4)
    }

    func test_unsubscribe() {
        let subscriber = TestSubscriber()
        subscriber.expectation = expectation(description: #function)
        store.subscribe(subscriber)
        store.unSubscribe(subscriber)

        store.dispatch(CountAction.Increment)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(subscriber.lastStates.count, 1)
    }

    func test_raceConditions() {
        let iters = 500

        let parent = UIViewController()
        var subscribers = [TestSubscriber]()

        let creator = ActionDispatcher<CounterState> { state, dispatch in
            dispatch(CountAction.Increment)
        }

        for _ in 1...iters {
            let child = TestSubscriber()
            parent.addChildViewController(child)
            parent.view.addSubview(child.view)

            scheduleInBackground {
                self.store.subscribe(child)
                self.store.dispatch(creator)
                self.store.dispatch(CountAction.Increment)
            }
            subscribers.append(child)
        }

        let expected = "\(iters * 2)"
        let exp = expectation(description: #function)
        scheduleInBackground {
            while subscribers.last?.label.text != expected {}
            exp.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        for subscriber in subscribers[1..<iters] {

            XCTAssertEqual(subscriber.label.text, expected)
        }
    }

    private func scheduleInBackground(block: @escaping () -> Void) {
        DispatchQueue.global().async(execute: block)
    }
}

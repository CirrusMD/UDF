//
//  StoreTest.swift
//  CirrusMD
//
//  Created by David Nix on 1/20/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

import XCTest
import UDF


class ReduxStoreTest: XCTestCase {

    typealias TestStore = Store<CounterState, TestReducer>
    let reducer = TestReducer()
    lazy var store: TestStore = {
        return Store(reducer: self.reducer, initialState: CounterState(), config: Config(debug: true))
    }()
    
    func test_currentState() {
        store.dispatch(CountAction.Increment)
        
        XCTAssertEqual(store.currentState().counter, 1)
    }
    
    func test_currentState_completion() {
        store.dispatch(CountAction.Increment)
        
        var exp = expectation(description: #function)
        var state: CounterState? = nil
        store.currentState {
            state = $0
            exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertEqual(state?.counter, 1)
        
        state = nil
        exp = expectation(description: #function)
        
        scheduleInBackground {
            self.store.dispatch(CountAction.Increment)
            self.store.currentState {
                state = $0
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertEqual(state?.counter, 2)
    }

    func test_dispatch_action() {
        reducer.expectation = expectation(description: #function)
        store.dispatch(CountAction.Increment)
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(reducer.didHandleAction)
        XCTAssertEqual(reducer.state?.counter, 1)
    }

    func test_dispatch_actionDispatcher() {
        reducer.expectation = expectation(description: #function)
        var capturedState: CounterState? = nil
        let dispatcher = ActionDispatcher<CounterState> { state, dispatch in
            capturedState = state()
            dispatch(CountAction.Increment)
        }
        store.dispatch(dispatcher)
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(capturedState?.counter, 0)
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
    
    //MARK: Race Conditions
    
    func test_callingCurrentStateSynchronouslyWithinUpdateState() {
        /* This is not supported and will deadlock, use the asynchronous method instead */
    }
    
    func test_subscribingFromWithingUpdateState() {
        let subscriber = TestSubscriber()
        subscriber.arbitraryClosure = {
            self.store.subscribe(TestSubscriber())
        }
        store.dispatch(CountAction.Increment)
        store.subscribe(subscriber)
        subscriber.expectation = expectation(description: #function)
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertEqual(subscriber.label.text, "1")
    }

    func test_subscribingFromDifferentThreads() {
        reducer.randomSleepInterval = 50_000
        let iters = 1000

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

        waitForExpectations(timeout: 200, handler: nil)

        for subscriber in subscribers[1..<iters] {

            XCTAssertEqual(subscriber.label.text, expected)
        }
    }

    private func scheduleInBackground(block: @escaping () -> Void) {
        DispatchQueue.global().async(execute: block)
    }
}

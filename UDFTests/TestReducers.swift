//
//  TestReducers.swift
//  UDF
//
//  Created by David Nix on 10/5/16.
//  Copyright © 2016 cirrusmd. All rights reserved.
//
import UDF
import XCTest

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
    var randomSleepInterval: UInt32?
    
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
        if let interval = randomSleepInterval {
//            Double(interval) * Double(Float(arc4random()) /  Float(UInt32.max))
            usleep(interval)
        }
        expectation?.fulfill()
        return state
    }
}


class TestSubscriber: UIViewController, Subscriber {
    typealias State = CounterState
    
    var lastStates: [CounterState] = []
    var previousStates: [CounterState?] = []
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    var arbitraryClosure: (() -> Void)?
    
    var expectation: XCTestExpectation?
    
    func updateState(previous: CounterState?, current: CounterState) {
        previousStates.append(previous)
        lastStates.append(current)
        label.text = "\(current.counter)"
        arbitraryClosure?()
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


class FilteredSubscriber: Subscriber {
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

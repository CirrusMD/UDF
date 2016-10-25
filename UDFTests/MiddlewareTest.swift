//
//  MiddlewareTest.swift
//  UDF
//
//  Created by David Nix on 10/25/16.
//  Copyright © 2016 cirrusmd. All rights reserved.
//

import XCTest
import UDF

typealias MiddlewareStore = Store<Int, MiddlewareReducer>

struct MiddlewareAction: Action {}

struct MiddlewareReducer: Reducer {
    typealias State = Int

    func handle(action: Action, forState state: State) -> State {
        return state + 1
    }
}

var middlewareTracking: [Int] = []

class MiddlewareCapture {
    let order: Int
    init(_ order: Int) {
        self.order = order
    }
    
    lazy var middleware: MiddlewareStore.Middleware = { state in
        return { next in
            return { action in
                middlewareTracking.append(self.order)
                next(action)
            }
        }
    }
}

class MiddlewareTest: XCTestCase {
    
    let reducer = MiddlewareReducer()
    lazy var middleware: [MiddlewareCapture] = {
        (0..<5).map {
            return MiddlewareCapture($0)
        }
    }()
    var store: MiddlewareStore!
    
    override func setUp() {
        super.setUp()
        middlewareTracking = []
        
        let funcs = self.middleware.map { $0.middleware }
        store = Store(reducer: self.reducer, initialState: 0, middleware: funcs, config: Config(debug: true))
    }
    
    func test_middleWare() {
        store.dispatch(MiddlewareAction())
        
        XCTAssertEqual(store.currentState(), 1)
        XCTAssertEqual(middlewareTracking, [0,1,2,3,4])
    }
}

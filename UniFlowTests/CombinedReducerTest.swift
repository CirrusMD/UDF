//
//  CombinedReducerTest.swift
//  CirrusMD
//
//  Created by David Nix on 3/28/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

import XCTest
import UniFlow


struct CombinedState {
    var message = ""
    var code = 0
}


struct CombinedAction: Action {}


class MessageReducer: Reducer {
    
    typealias State = CombinedState
    
    func handle(action: Action, forState state: State) -> State {
        var state = state
        
        state.message = "You have been reduced, sir!"
        
        return state
    }
}


class CodeReducer: Reducer {
    
    typealias State = CombinedState
    
    func handle(action: Action, forState state: State) -> State {
        var state = state
        
        state.code = 99001
        
        return state
    }
}



class CombinedReducerTest: XCTestCase {
    
    let combinedReducer = CombinedReducer<CombinedState> {
        $0.add(reducer: MessageReducer())
        $0.add(reducer: CodeReducer())
    }

    func test_handleAction() {
        let state = combinedReducer.handle(action: CombinedAction(), forState: CombinedState())
        
        XCTAssertEqual(state.message, "You have been reduced, sir!")
        XCTAssertEqual(state.code, 99001)
    }
}

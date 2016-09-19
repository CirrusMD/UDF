//
//  CombinedReducerTest.swift
//  CirrusMD
//
//  Created by David Nix on 3/28/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

import XCTest
import UniFlow


private struct CombinedState {
    var message = ""
    var code = 0
}


private struct CombinedAction: Action {}


private class MessageReducer: Reducer {
    
    typealias State = CombinedState
    
    private func handleAction(action: Action, forState state: State) -> State {
        var state = state
        
        state.message = "You have been reduced, sir!"
        
        return state
    }
}


private class CodeReducer: Reducer {
    
    typealias State = CombinedState
    
    private func handleAction(action: Action, forState state: State) -> State {
        var state = state
        
        state.code = 99001
        
        return state
    }
}



class CombinedReducerTest: CMDTestCase {
    
    private let combinedReducer = CombinedReducer<CombinedState> {
        $0.add(MessageReducer())
        $0.add(CodeReducer())
    }

    func test_handleAction() {
        let state = combinedReducer.handleAction(CombinedAction(), forState: CombinedState())
        
        XCTAssertEqual(state.message, "You have been reduced, sir!")
        XCTAssertEqual(state.code, 99001)
    }
}

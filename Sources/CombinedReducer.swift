//
//  CombinedReducer.swift
//
//  Created by David Nix on 3/28/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//
//  Attribution:
//  Created by Benjamin Encz on 11/11/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//  https://github.com/ReSwift/ReSwift
//


public class CombinedReducer<StateType>: Reducer {
    public typealias builder = (CombinedReducer) -> Void

    fileprivate let reducers: [ReducerType]
    
    public init(_ reducers: [ReducerType]) {
        self.reducers = reducers
    }

    //MARK: Reducer
    public typealias State = StateType

    public func handle(action: Action, forState state: State) -> State {
        return reducers.reduce(state) { (origState, reducer) -> State in
            return reducer._handle(action: action, forState: origState) as? State ?? origState
        }
    }
}

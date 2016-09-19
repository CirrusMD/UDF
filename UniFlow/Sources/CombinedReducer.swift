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
    
    public init(_ build: builder) {
        build(self)
    }
    
    private var reducers = [ReducerType]()
    
    public func add<R: Reducer where R.State == StateType>(reducer: R) {
        reducers.append(reducer)
    }
    
    //MARK: Reducer
    public typealias State = StateType
    
    public func handleAction(action: Action, forState state: State) -> State {
        return reducers.reduce(state) { (acc, reducer) -> State in
            var acc = acc
            if let newState = reducer._handleAction(action, forState: acc) as? State {
                acc = newState
            }
            return acc
        }
    }
}
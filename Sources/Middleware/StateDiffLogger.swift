//
//  StateDiffLogger.swift
//  UDF
//
//  Created by David Nix on 10/25/16.
//  Copyright © 2016 cirrusmd. All rights reserved.
//


public func StateDiffLogger<State>(state: @escaping () -> State) -> (@escaping DispatchFunc) -> DispatchFunc {
    return { next in
        return { action in
            let prev = state()
            next(action)
            let current = state()
            print("[UDF: State Diff]:\n")
            print(debugDiff(lhs: prev, rhs: current))
        }
    }
}

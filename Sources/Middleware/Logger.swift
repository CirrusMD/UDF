//
//  Logger.swift
//  UDF
//
//  Created by David Nix on 10/25/16.
//  Copyright © 2016 cirrusmd. All rights reserved.
//

private let prefix = "[UDF: DEBUG]"

public func DebugLogger<State>(state: @escaping () -> State) -> (@escaping DispatchFunc) -> DispatchFunc {
    return { next in
        return { action in
            print(prefix, "DISPATCHED ACTION", action)
            let start = Date()
            
            next(action)
            
            var duration =  abs(start.timeIntervalSinceNow) * 1000
            var unit = "ms"
            if duration < 1000 {
                duration *= 1000
                unit = "μs"
            }
            print(prefix, "Time to reduce state: \(duration) \(unit)")
        }
    }
}

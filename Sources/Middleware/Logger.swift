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
            
            let duration =  abs(start.timeIntervalSinceNow) * 1_000 // milliseconds
            let formatted = formatter.string(from: NSNumber(value: duration)) ?? "unknown"
            print(prefix, "Time to reduce state: \(formatted) ms")
        }
    }
}

private let formatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.locale = NSLocale.current
    f.alwaysShowsDecimalSeparator = true
    f.minimumFractionDigits = 3
    f.maximumFractionDigits = 3
    f.groupingSeparator = ","
    f.usesGroupingSeparator = true
    return f
}()

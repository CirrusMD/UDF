//
//  Config.swift
//  UDF
//
//  Created by David Nix on 9/27/16.
//  Copyright © 2016 cirrusmd. All rights reserved.
//


public struct Config {
    public let debug: Bool
    
    public init(debug: Bool) {
        self.debug = debug
    }
}

extension Config {
    public static let `default` = Config(debug: false)
}

//
//  Action.swift
//  CirrusMD
//
//  Created by David Nix on 3/28/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//
//  Attribution:
//  Created by Benjamin Encz on 12/14/15.
//  Copyright © 2015 Benjamin Encz. All rights reserved.
//  https://github.com/ReSwift/ReSwift
//


public typealias DispatchFunc = (Action) -> Void

public protocol Action {}


public struct ActionDispatcher<State>: CustomStringConvertible {

    public typealias GetState = () -> State
    public typealias CreateFunc = (GetState, DispatchFunc) -> Void

    public let dispatch: CreateFunc
    fileprivate let identifier: String

    public init(identifier: String = UUID().uuidString, createFunc: @escaping CreateFunc) {
        self.identifier = identifier
        self.dispatch = createFunc
    }

    public var description: String {
        return "\(ActionDispatcher.self): \(identifier)"
    }
}

extension ActionDispatcher: Equatable {}
public func == <T>(lhs: ActionDispatcher<T>, rhs: ActionDispatcher<T>) -> Bool {
    return lhs.identifier == rhs.identifier
}

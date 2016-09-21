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

public protocol Action {}


public typealias DispatchFunc = (Action) -> Void


public struct ActionDispatcher<State>: CustomStringConvertible {

    public typealias GetState = () -> State
    public typealias Dispatcher = (@escaping GetState, @escaping DispatchFunc) -> Void

    public let dispatch: Dispatcher
    fileprivate let identifier: String

    public init(identifier: String = UUID().uuidString, dispatcher: @escaping Dispatcher) {
        self.identifier = identifier
        self.dispatch = dispatcher
    }

    public var description: String {
        return "\(ActionDispatcher.self): \(identifier)"
    }
}

extension ActionDispatcher: Equatable {}
public func == <T>(lhs: ActionDispatcher<T>, rhs: ActionDispatcher<T>) -> Bool {
    return lhs.identifier == rhs.identifier
}

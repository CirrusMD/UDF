//
//  CirrusMD
//
//  Created by David Nix on 1/20/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//
//  Attribution:
//  Created by Benjamin Encz on 12/14/15.
//  Copyright © 2015 Benjamin Encz. All rights reserved.
//  https://github.com/ReSwift/ReSwift
//

public protocol ReducerType {
    func _handleAction(action: Action, forState state: Any) -> Any
}


public protocol Reducer: ReducerType {
    associatedtype State

    func handleAction(action: Action, forState state: State) -> State
}


extension Reducer {
    public func _handleAction(action: Action, forState state: Any) -> Any {
        guard let typedState = state as? State else {
            assertionFailure("Reducer \(self) handled unexpected state \(state)")
            return state
        }
        return handleAction(action, forState: typedState)
    }
}

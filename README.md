# UDF
[Unidirectional data flow](http://redux.js.org/docs/basics/DataFlow.html) in Swift via a single state container. Inspired by [Redux](https://github.com/reactjs/redux). Designed for Cocoa and Cocoa Touch.

UDF is a fork of [ReSwift](https://github.com/ReSwift/ReSwift). UDF is a minimal dependency to make your view controllers a function of state.

With React, React will diff the DOM for you, making minimal changes. You can change the state as much as you'd like with minimal consequences. Cocoa does not give you this luxury.

There are 3rd party libraries that attempt to mimic React by diffing the view hierarchy. Some even have their own layout DSL. 

UDF is designed to be a minimal and isolated dependency. Therefore, it does not attempt to improve or extend view layout or hierarchy in Cocoa. It allows you to use conventional Cocoa view programming. 

So, if we don't diff the view hierarchy? What are we left with.

UDF attempts to capture the **transition** between states. Therefore, your view controllers can react to a state change. It attempts to remove responsibility from a view controller from checking its state and making a change based on a new state.

## Why a Fork of ReSwift?

* UDF is thread-safe. You can dispatch an action from any thread.
* Simpler dispatch API
* UDF wants to capture the transitions between states, so your view controllers can react to the transitions.

## Features
* Thread safe
* Non-blocking
* Deadlock detection (but needs improvement)
* Subscribers do not have to unsubscribe (but it's recommended)
* Safe to call subscribe multiple times. UDF will only subscribe an object once

## Advantages and Tradeoffs
### Advantages
* Use plain old Cocoa or any 3rd party solution of your choice to build your view hierarchy
* Limits communication between parent and child view controllers, so you can use child view controllers liberally.
* Dispatching

### Tradeoffs
* All tradeoffs associated with the Observer pattern. It may be hard to see cause and effect. UDF's debug logging attempts to help you trace cause and effect.
* The `previous` state in `updateState(previous: current:)` is nil only for the initial state. (i.e. before any actions are dispatched). It is non-nil after that. Having `previous` as optional is not ideal
  
### Best Practices
* Reducers should do their work quickly.
* Reducers should be free of side effects.
* Limit derived state in your state tree.

## Gotchas
* Reducers do their work on a background queue. (Although, this is a feature to keep dispatching non-blocking)
* Don't subscribe in an `init`. UDF should work as intended but you could flood the subscriber pool with many unnecessary subscribers.
* Don't unsubscribe in a `deinit`. This is unstable and may crash because the subscriber attempts to unsubscribe as it's deallocated. (Working to fix this.)
* Don't mix poor man's diffing using `previous` and `current` states with `Version`ed values.

###TODO
Near future:
* For real documentation
* config options
* middleware
* macOS support

Sometime in the Future:
* time travel debugging

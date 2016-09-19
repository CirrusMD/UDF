# UniFlow
[Unidirectional data flow](http://redux.js.org/docs/basics/DataFlow.html) in Swift via a single state container. Inspired by [Redux](https://github.com/reactjs/redux). Designed for Cocoa and Cocoa Touch.

UniFlow is a fork of [ReSwift](https://github.com/ReSwift/ReSwift). UniFlow is a minimal dependency to make your view controllers a function of state.

With React, React will diff the DOM for you, making minimal changes. You can change the state as much as you'd like with minimal consequences. Cocoa does not give you this luxury.

There are 3rd party libraries that attempt to mimic React by diffing the view hierarchy. Some even have their own layout DSL. 

UniFlow is designed to be a minimal and isolated dependency. Therefore, it does not attempt to improve or extend view layout or hierarchy in Cocoa. It allows you to use conventional Cocoa view programming. 

So, if we don't diff the view hierarchy? What are we left with.

UniFlow attempts to capture the **transition** between states. Therefore, your view controllers can react to a state change. It attempts to remove responsibility from a view controller from checking its state and making a change based on a new state.

## Why a Fork of ReSwift?

* UniFlow is thread-safe. You can dispatch an action from any thread.
* Simpler dispatch API
* UniFlow wants to capture the transitions between states, so your view controllers can react to the transitions.

## Features
* Thread safe
* Non-blocking
* Deadlock detection

## Gotchas
* Reducers do their work on a background queue.
* Don't subscribe in an `init`. UniFlow will be stable, but you will probably.
* Don't unsubscribe in a `deinit`. This is unstable and may crash because the subscriber attempts to unsubscribe as it's deallocated.

###TODO
Near future:
* config options
* middleware
* macOS support

Far Future:
* time travel debugging
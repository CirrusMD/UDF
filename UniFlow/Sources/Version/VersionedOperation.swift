//
//  VersionedOperation.swift
//  CirrusMD
//
//  Created by David Nix on 3/29/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//


open class VersionedOperation<T>: Operation {

    fileprivate let key: TrackableKey
    fileprivate let version: Version<T>
    fileprivate let task: () -> Void
    
    public init(key: AnyObject, version: Version<T>, task: @escaping () -> Void) {
        self.key = TrackableKey(key)
        self.task = task
        self.version = version
        super.init()
    }
    
    open override func main() {
        guard !isCancelled && key.objectRef != nil else {
            return
        }
        
        guard !versionExists(key, version: version) else {
            return
        }
        
        task()
    }
}


private struct TrackableKey: Hashable {
    weak var objectRef: AnyObject?
    let hashValue: Int
    
    init(_ objectRef: AnyObject) {
        self.hashValue = ObjectIdentifier(objectRef).hashValue
        self.objectRef = objectRef
    }
}

private func ==(lhs: TrackableKey, rhs: TrackableKey) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

private let mutex = DispatchQueue(label: "com.cirrusmd.exclusiveOperation", attributes: DispatchQueue.Attributes.concurrent)
private var HISTORY = [TrackableKey: [Int: Bool]]()

private func versionExists<T>(_ key: TrackableKey, version: Version<T>) -> Bool {
    defer {
        cleanUpHistory()
    }
    
    var executed = false
    mutex.sync(flags: .barrier, execute: {
        executed = HISTORY[key]?[version.hashValue] ?? false
        
        if !executed {
            var versions = HISTORY[key] ?? [Int: Bool]()
            versions[version.hashValue] = true
            HISTORY[key] = versions
        }
    }) 
    return executed
}

private func cleanUpHistory() {
    mutex.async { 
        HISTORY.keys.filter({ $0.objectRef == nil}).forEach {
            HISTORY.removeValue(forKey: $0)
        }
    }
}

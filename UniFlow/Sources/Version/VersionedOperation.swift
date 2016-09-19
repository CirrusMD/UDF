//
//  VersionedOperation.swift
//  CirrusMD
//
//  Created by David Nix on 3/29/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//


public class VersionedOperation<T>: NSOperation {

    private let key: TrackableKey
    private let version: Version<T>
    private let task: () -> Void
    
    public init(key: AnyObject, version: Version<T>, task: () -> Void) {
        self.key = TrackableKey(key)
        self.task = task
        self.version = version
        super.init()
    }
    
    public override func main() {
        guard !cancelled && key.objectRef != nil else {
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

private let mutex = dispatch_queue_create("com.cirrusmd.exclusiveOperation", DISPATCH_QUEUE_CONCURRENT)
private var HISTORY = [TrackableKey: [Int: Bool]]()

private func versionExists<T>(key: TrackableKey, version: Version<T>) -> Bool {
    defer {
        cleanUpHistory()
    }
    
    var executed = false
    dispatch_barrier_sync(mutex) {
        executed = HISTORY[key]?[version.hashValue] ?? false
        
        if !executed {
            var versions = HISTORY[key] ?? [Int: Bool]()
            versions[version.hashValue] = true
            HISTORY[key] = versions
        }
    }
    return executed
}

private func cleanUpHistory() {
    dispatch_async(mutex) { 
        HISTORY.keys.filter({ $0.objectRef == nil}).forEach {
            HISTORY.removeValueForKey($0)
        }
    }
}
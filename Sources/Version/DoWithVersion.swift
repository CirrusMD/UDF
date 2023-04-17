//
//  VersionedOperation.swift
//  CirrusMD
//
//  Created by David Nix on 3/29/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

import Foundation

@discardableResult public func DoWithVersion<T>(key: AnyObject, version: Version<T>, task: () -> Void) -> Bool {
    let trackable = TrackableKey(key)
    guard trackable.objectRef != nil else {
        return false
    }
    guard !versionExists(trackable, version: version) else {
        return false
    }
    task()
    return true
}

private struct TrackableKey: Hashable {
    weak var objectRef: AnyObject?
    
    init(_ objectRef: AnyObject) {
        self.objectRef = objectRef
    }
    
    func hash(into hasher: inout Hasher) {
        guard let objectRef = objectRef else {
            return
        }
        hasher.combine(ObjectIdentifier(objectRef))
    }
    
    static func == (lhs: TrackableKey, rhs: TrackableKey) -> Bool {
        guard let left = lhs.objectRef, let right = rhs.objectRef else {
            return false
        }
        return left === right
    }
}

private let mutex = DispatchQueue(label: "com.cirrusmd.UDF.versions", attributes: DispatchQueue.Attributes.concurrent)
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

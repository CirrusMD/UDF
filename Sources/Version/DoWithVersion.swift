//
//  VersionedOperation.swift
//  CirrusMD
//
//  Created by David Nix on 3/29/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

import Foundation

public func DoWithVersion<T>(key: AnyObject, version: Version<T>, task: () -> Void) {
    let trackable = TrackableKey(key)
    guard trackable.objectRef != nil else {
        return
    }
    guard !versionExists(trackable, version: version) else {
        return
    }
    task()
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

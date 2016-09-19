//
//  Version.swift
//  CirrusMD
//
//  Created by David Nix on 3/29/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

public struct Version<T> {
    public let value: T
    private let uuid: String
    
    public init(_ versionable: T) {
        uuid = NSUUID().UUIDString
        value = versionable
    }
}

extension Version: Hashable {
    public var hashValue: Int {
        return uuid.hashValue
    }
}

public func ==<T>(lhs: Version<T>, rhs: Version<T>) -> Bool {
    return lhs.uuid == rhs.uuid
}

extension Version: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Version of \(value). UUID: \(uuid)"
    }
}

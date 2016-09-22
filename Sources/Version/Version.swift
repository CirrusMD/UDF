//
//  Version.swift
//  CirrusMD
//
//  Created by David Nix on 3/29/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

import Foundation


public struct Version<T> {
    public let value: T
    fileprivate let uuid: String

    public init(_ versionable: T) {
        uuid = UUID().uuidString
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

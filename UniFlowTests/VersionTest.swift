//
//  VersionTest.swift
//  CirrusMD
//
//  Created by David Nix on 3/29/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

import XCTest
import UniFlow


class VersionTest: XCTestCase {

    func test_hashable() {
        let version1 = Version(67)

        XCTAssertEqual(version1, version1)

        let version2 = Version("67")

        XCTAssertEqual(version2, version2)

        let version3 = Version(68)

        XCTAssertEqual(version3, version3)

        XCTAssertNotEqual(version1.hashValue, version2.hashValue)
        XCTAssertNotEqual(version1, version3)
    }
}

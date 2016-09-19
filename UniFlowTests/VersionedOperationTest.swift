//
//  CirrusMD
//
//  Created by David Nix on 3/29/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

import XCTest
import UniFlow


private struct TestVersionable: Hashable {
    let hash = NSUUID().hashValue
    
    var hashValue: Int {
        return hash
    }
}


private func ==(lhs: TestVersionable, rhs: TestVersionable) -> Bool {
    return lhs.hashValue == rhs.hashValue
}


class ExclusiveOperationTest: XCTestCase {
    
    let queue = NSOperationQueue()
    
    override func setUp() {
        super.setUp()
        
        queue.maxConcurrentOperationCount = 1
    }
    
    func test_execute() {
        let key = UIViewController()
        let version = Version(TestVersionable())
        
        let tests: [(UIViewController, Version<TestVersionable>, Bool)] = [
            (key, version, true),
            (key, version, false),
            (key, Version(TestVersionable()), true),
            (UIViewController(), version, true),
            (key, version, false),
            (key, version, false),
            (key, version, false),
        ]
        
        for (index, (key, version, expectation)) in tests.enumerate() {
            var executed = false
            let op = VersionedOperation(key: key, version: version) {
                executed = true
            }
            queue.addOperations([op], waitUntilFinished: true)
            
            if executed != expectation {
                XCTFail("test case# \(index+1): expected \(expectation), got \(executed)")
            }
        }
        
    }
}

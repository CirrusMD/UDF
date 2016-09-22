//
//
//  Created by David Nix on 4/9/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//

import Foundation


func debugDiff(lhs: Any, rhs: Any) -> String {

    var lhsString = ""
    debugPrint(lhs, to: &lhsString)
    let lhsLines = lhsString.components(separatedBy: CharacterSet.newlines)

    var rhsString = ""
    debugPrint(rhs, to: &rhsString)
    let rhsLines = rhsString.components(separatedBy: CharacterSet.newlines)

    let diffText =  zip(lhsLines, rhsLines).reduce("") { (acc, linePair: (String, String)) -> String in
        var acc = acc
        let (lhs, rhs) = linePair

        var lines = lhs
        if lhs != rhs {
            lines = "- \(lhs)\n+ \(rhs)"
        }

        acc = acc + "\n" + lines
        return acc
    }

    return diffText
}

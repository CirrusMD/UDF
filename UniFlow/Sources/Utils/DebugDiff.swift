//
//
//  Created by David Nix on 4/9/16.
//  Copyright © 2016 CirrusMD. All rights reserved.
//


func debugDiff(lhs: Any, rhs: Any) -> String {
    
    var lhsString = ""
    debugPrint(lhs, toStream: &lhsString)
    let lhsLines = lhsString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
    
    var rhsString = ""
    debugPrint(rhs, toStream: &rhsString)
    let rhsLines = rhsString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
    
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

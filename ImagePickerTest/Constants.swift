import Foundation
import UIKit

struct Placeholder {
    
    static let topText = "TOP TEXT"
    static let bottomText = "BOTTOM TEXT"
}

var kdefaultFontName: String = "HelveticaNeue-CondensedBlack" {
    
    didSet {
        kDefaultFont = UIFont(name: kdefaultFontName, size: 40)!
        
        print("default font: \(String(describing: kDefaultFont))")
    }
}

var kDefaultFont = UIFont(name: kdefaultFontName, size: 40) {
    didSet {
        print("Just got set to: \(kdefaultFontName)")
    }
}

let kPreferredFont = UIFont(name: "HelveticaNeue-CondensedBlack", size: 17)


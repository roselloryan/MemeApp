import UIKit

extension UILabel {
    
    var defaultFontName : String {
        get { return self.font.fontName }
        
        set { self.font = UIFont(name: newValue, size: self.font.pointSize) }
    }
    
}

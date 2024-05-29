import Cocoa
import CoreGraphics
import Foundation

class TextLayoutFragmentLayer: CALayer {
    var layoutFragment: NSTextLayoutFragment!
    
    let strokeWidth: CGFloat = 2
    
    override class func defaultAction(forKey: String) -> CAAction? {
        // Suppress default opacity animations.
        return NSNull()
    }

    func updateGeometry() {
        bounds = layoutFragment.renderingSurfaceBounds
                
        // The (0, 0) point in layer space should be the anchor point.
        anchorPoint = CGPoint(x: -bounds.origin.x / bounds.size.width, y: -bounds.origin.y / bounds.size.height)
        position = layoutFragment.layoutFragmentFrame.origin
        var newBounds = bounds

        // On macOS 14 and iOS 17, NSTextLayoutFragment.renderingSurfaceBounds is properly relative to the NSTextLayoutFragment's
        // interior coordinate system, and so this sample no longer needs the inconsistent x origin adjustment.
        if #unavailable(iOS 17, macOS 14) {
            newBounds.origin.x += position.x
        }
        bounds = newBounds
    }
    
    init(layoutFragment: NSTextLayoutFragment) {
        self.layoutFragment = layoutFragment
        
        super.init()
        
        contentsScale = 2
        updateGeometry()
        setNeedsDisplay()
    }
    
    override init(layer: Any) {
        guard let tlfLayer = layer as? TextLayoutFragmentLayer else {
            fatalError("The type of `layer` needs to be TextLayoutFragmentLayer.")
        }
        layoutFragment = tlfLayer.layoutFragment
        
        super.init(layer: layer)
        updateGeometry()
        setNeedsDisplay()
    }
    
    required init?(coder: NSCoder) {
        layoutFragment = nil
        
        super.init(coder: coder)
    }
    
    override func draw(in ctx: CGContext) {
        layoutFragment.draw(at: .zero, in: ctx)
    }
}

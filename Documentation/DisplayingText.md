# Editor
## 1 Displaying text

The first step of a text editor is displaying text. For this, Apple have a very good example project that handles this I've used as the basis for my text editor, although I've simplified the codebase and fixed a few bugs.

### Creating the view

The three things the view needs are
* A `NSTextContentStorage` as a source for the text.
* A `NSTextContainer` to describe the shape of the area for text display.
* A `NSTextLayoutManager` to layout the contents of the `NSTextContentStorage` in the area described by the `NSTextContainer`

To actually get text on the screen, TextKit will pass individual `NSTextLayoutFragment`s to a delegate method and I'll use `CALayer`s to display them, the same as the Apple example as I don't think I'll need the extra overhead of `NSView` at the moment. The view will therefore need a sublayer to hold all the text fragment layers.

None of the objects created need anything complicated, so the view initialisation is fairly straightforward.

```swift
    wantsLayer = true
    
    contentLayer = CALayer()
    layer?.addSublayer(contentLayer)
    
    textLayoutManager = NSTextLayoutManager()
    
    textContentStorage = NSTextContentStorage()
    textContentStorage.addTextLayoutManager(textLayoutManager)

    let textContainer = NSTextContainer(size: .zero)
    textLayoutManager.textContainer = textContainer

    textLayoutManager.textViewportLayoutController.delegate = self
```

The text container size is set to `zero` initially, but will get updated later once the view size is known. Finally, the view is set as a delegate for the `NSTextViewportLayoutController` inside the layout manager. This controls the text layout inside the viewport, which is usually the visible region with some extra for overscroll.

One quirk to note is that `NSTextViewportLayoutController.delegate` cannot be set if the layout manager does not have an attached text container. It doesn't generate any error, but the `delegate` value will be `nil`, which can create a difficult to track down bug.

Once everything is created, text can be put in the `NSTextStorage` which is a subclass of `NSAttributedString`. 

```swift
        let attrText = NSMutableAttributedString(string: text)
        let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize + 10, weight: .regular)
        attrText.addAttribute(.font, value: font, range: NSRange(location: 0, length: text.count))

        textContentStorage.textStorage?.setAttributedString(attrText)

        textLayoutManager.setRenderingAttributes([.foregroundColor: NSColor.textColor],
                                                    for: textContentStorage.documentRange)
```

The font is set on the string directly, but the text colour is set on the `NSTextLayoutManager` as rendering attributes. I assume only attribute keys that don't affect layout are valid as rendering attributes, but I've not seen it mentioned in the documentation.

### Getting the correct size for layout

Now the view is set up, the first part of getting the text onscreen is to work out what size everything needs to be. In this editor the size of the `NSTextContainer` will follow the size of the view, so the size of the view needs to be set from the layout size.

The `NSTextContainer` was initialised to be `.zero` giving a width and a height of 0. `NSTextContainer` takes a 0 to mean as big as necessary in that direction, but it cannot work when both values are 0 because it needs one fixed value to use as a limit. If a layout pass is attempted with both values set to 0, then the layout will just calculate the layout for the first fragment.

The sizing process is split into 3 methods that can be run individually, or in a coordinated fashion so the minimum amount of laying out is done. The layout size is calculated in the `updateContentSizeIfNeeded()` method, the size of the `NSTextContainer` is set using the `updateTextContainerSize()` method, and the overriden `setFrameSize()` method updates the view size, and coordinates the rest.

The most interesting of these methods is the one that calculates the content size: `updateContentSizeIfNeeded()`

```swift
        let currentHeight = bounds.height
        var height: CGFloat = 0
        textLayoutManager.enumerateTextLayoutFragments(from: textLayoutManager.documentRange.endLocation,
                                                        options: [.reverse, .ensuresLayout]) { layoutFragment in
            height = layoutFragment.layoutFragmentFrame.maxY

            return false // stop
        }

        height += (padding.top + padding.bottom)
        height = max(height, enclosingScrollView?.contentSize.height ?? 0)

        if abs(currentHeight - height) > 1e-10 {
            let contentSize = NSSize(width: bounds.width, height: height)
            setFrameSize(contentSize)
        }
```

An `NSTextLayoutFragment` is an individual paragraph which is any run of text up to a newline. If the `NSTextLayoutFragment` has been fully laid out (if `NSTextLayoutFragment.state` is equal to `.layoutAvailable`) it will contain a number of `NSTextLineFragment`s in the `textLineFragments` array which correspond to the individual visual lines that the paragraph has been wrapped onto, and the `NSTextLineFragment`s have access to the actual string that they represent and layout information like the `typographicBounds`.

The core of this method is using the `.reverse` and `.ensuresLayout` options for `enumerateTextLayoutFragments(from:options:using:)` method, it takes the `maxY` position of the last `NSTextLayoutFragment` from the `NSTextLayoutManager`, returning `false` from the closure to stop the enumeration after one item, and that's the height of the content. 

Some padding is added and it is checked against the height of the scrollview before setting the frame size if the content height has changed.

`setFrameSize()` and `updateTextContainerSize()` don't do much that is unexpected: `setFrameSize()` sets the `contentLayer` to the same size as the view's new frame, then updates the size of the `NSTextContainer`. If the size did change, the `setFrameSize()` calls the `updateContentSizeIfNeeded()` method. And so, with this arrangement, the correct size will be set for `NSTextContainer` before the first call to `updateContentSizeIfNeeded()`

```swift
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        contentLayer.frame = bounds
        
        if updateTextContainerSize() {
            updateContentSizeIfNeeded()
        }
    }

    func updateTextContainerSize() -> Bool {
        if textContainer.size.width != bounds.width - (padding.left + padding.right) {
            textContainer.size = NSSize(width: bounds.size.width - (padding.left + padding.right),
                                        height: 0)
            layer?.setNeedsLayout()
            return true
        }
        
        return false
    }
```

`updateTextContainerSize()` still keeps the height of the text container as 0 to let the layout know it should take as much vertical space as it needs for layout.

### Putting text on screen

With the correct size set for the view and the `NSTextContainer` the second step of the process is for the `NSTextViewportLayoutController` to start laying out the text into the specified viewport. To start this process off, the view needs to conform to the `CALayerDelegate` protocol so it can receive the `layoutSublayers(of:)` method.

```swift
extension EditorView: CALayerDelegate {
    func layoutSublayers(of layer: CALayer) {
        assert(layer == self.layer)
        textLayoutManager?.textViewportLayoutController.layoutViewport()
    }
}
```

`NSTextViewportLayoutController` will check with its delegate to see what the size of the viewport is and will start laying the text fragments out by calling the delegate's `textViewportLayoutController(_ controller: NSTextViewportLayoutController,configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment)` method.

```swift
        let (layer, layerIsNew) = findOrCreateLayer(textLayoutFragment)
        if !layerIsNew {
            let oldBounds = layer.bounds
            
            layer.updateGeometry()
                        
            if oldBounds != layer.bounds {
                layer.setNeedsDisplay()
            }
        }
        
        layer.position.x += padding.left
        layer.position.y += padding.top
        
        contentLayer.addSublayer(layer)
```

A text layer is either retrieved from the cache or created and then it is placed on the `contentLayer` in the correct place. The layer is a custom `CALayer` subclass called `TextLayoutFragmentLayer` and in it renders the `NSTextLayoutFragment` in its `draw(in:)` method.

```swift
override func draw(in ctx: CGContext) {
    layoutFragment.draw(at: .zero, in: ctx)
}
```
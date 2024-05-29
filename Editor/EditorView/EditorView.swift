//
//  EditorView.swift
//  Editor
//
//  Created by iain on 28/05/2024.
//

import AppKit
import Foundation

class EditorView: NSView {
    var textLayoutManager: NSTextLayoutManager!
    var textContentStorage: NSTextContentStorage!
    
    private var boundsDidChangeObserver: Any? = nil
    
    var contentLayer: CALayer! = nil
    var fragmentLayerMap: NSMapTable<NSTextLayoutFragment, CALayer>!
    var padding: NSEdgeInsets!
    
    init(with text: String) {
        super.init(frame: .zero)
        commonInit(with: text)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit(with: "")
    }
    
    func commonInit(with text: String) {
        wantsLayer = true
        
        contentLayer = CALayer()
        layer?.addSublayer(contentLayer)
        
        padding = NSEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
        
        fragmentLayerMap = .weakToWeakObjects()
        
        textLayoutManager = NSTextLayoutManager()
        
        textContentStorage = NSTextContentStorage()
        textContentStorage.addTextLayoutManager(textLayoutManager)

        let textContainer = NSTextContainer(size: .zero)
        textLayoutManager.textContainer = textContainer

        textLayoutManager.textViewportLayoutController.delegate = self
        
        let attrText = NSMutableAttributedString(string: text)
        let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize + 10, weight: .regular)
        attrText.addAttribute(.font, value: font, range: NSRange(location: 0, length: text.count))
        
        textContentStorage.textStorage?.setAttributedString(attrText)
        
        textLayoutManager.setRenderingAttributes([.foregroundColor: NSColor.textColor],
                                                 for: textContentStorage.documentRange)
    }
    
    deinit {
        if let observer = boundsDidChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - Overrides
extension EditorView {
    override var isFlipped: Bool { true }

    // Responsive scrolling.
    override class var isCompatibleWithResponsiveScrolling: Bool { return true }
    override func prepareContent(in rect: NSRect) {
        layer!.setNeedsLayout()
        super.prepareContent(in: rect)
    }
    
    // Live resize.
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        adjustViewportOffsetIfNeeded()
        updateContentSizeIfNeeded()
    }
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        let clipView = scrollView?.contentView
        if clipView != nil {
            NotificationCenter.default.removeObserver(self,
                                                      name: NSView.boundsDidChangeNotification,
                                                      object: clipView)
        }
        
        super.viewWillMove(toSuperview: newSuperview)
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        
        let clipView = scrollView?.contentView
        if clipView != nil {
            boundsDidChangeObserver = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification,
                                                                             object: clipView,
                                                                             queue: nil)
            { [weak self] notification in
                self!.layer?.setNeedsLayout()
            }
        }
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        contentLayer.frame = bounds
        
        if updateTextContainerSize() {
            updateContentSizeIfNeeded()
        }
    }
}

// MARK: - Public API
extension EditorView {
    func updateContentSizeIfNeeded() {
        guard let textLayoutManager else {
            return
        }
        
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
    }
}

// MARK: - Private
internal extension EditorView {
    var scrollView: NSScrollView? {
        guard let result = enclosingScrollView else {
            return nil
        }
        
        if result.documentView == self {
            return result
        } else {
            return nil
        }
    }
    
    
    func adjustViewportOffsetIfNeeded() {
        guard let contentView = scrollView?.contentView,
              let viewportLocation = textLayoutManager?.textViewportLayoutController.viewportRange?.location,
              let documentRange = textLayoutManager?.documentRange else {
            return
        }
        
        let contentOffset = contentView.bounds.minY
        if contentOffset < contentView.bounds.height &&
            viewportLocation.compare(documentRange.location) == .orderedDescending {
            // Nearing top, see if we need to adjust and make room above.
            adjustViewportOffset()
        } else if viewportLocation.compare(documentRange.location) == .orderedSame {
            // At top, see if we need to adjust and reduce space above.
            adjustViewportOffset()
        }
    }

    func adjustViewportOffset() {
        guard let viewportLayoutController = textLayoutManager?.textViewportLayoutController,
              let viewportLocation = viewportLayoutController.viewportRange?.location else {
            return
        }
        var layoutYPoint: CGFloat = 0
        
        textLayoutManager!.enumerateTextLayoutFragments(from: viewportLocation,
                                                        options: [.reverse, .ensuresLayout]) { layoutFragment in
            layoutYPoint = layoutFragment.layoutFragmentFrame.origin.y
            return true
        }
        
        if layoutYPoint != 0 {
            let adjustmentDelta = bounds.minY - layoutYPoint
            
            viewportLayoutController.adjustViewport(byVerticalOffset: adjustmentDelta)
            
            scroll(CGPoint(x: scrollView!.contentView.bounds.minX, y: scrollView!.contentView.bounds.minY + adjustmentDelta))
        }
    }

    func updateTextContainerSize() -> Bool {
        guard let textContainer = textLayoutManager?.textContainer else {
            return false
        }
        
        if textContainer.size.width != bounds.width - (padding.left + padding.right) {
            textContainer.size = NSSize(width: bounds.size.width - (padding.left + padding.right),
                                        height: 0)
            layer?.setNeedsLayout()
            return true
        }
        
        return false
    }
}


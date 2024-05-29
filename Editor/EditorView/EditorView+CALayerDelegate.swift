//
//  EditorView+CALayerDelegate.swift
//  Editor
//
//  Created by iain on 28/05/2024.
//

import AppKit
import Foundation

extension EditorView: CALayerDelegate {
    func layoutSublayers(of layer: CALayer) {
        assert(layer == self.layer)
        textLayoutManager?.textViewportLayoutController.layoutViewport()
    }
}

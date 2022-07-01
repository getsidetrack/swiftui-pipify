//
//  LayerView.swift
//  Dockable
//
//  Created by James Sherlock on 01/07/2022.
//

import SwiftUI

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
import UIKit
struct LayerView: UIViewRepresentable {
    let layer: CALayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.layer.addSublayer(layer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
#elseif os(macOS)
import Cocoa
struct LayerView: NSViewRepresentable {
    let layer: CALayer
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.layer?.addSublayer(layer)
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif

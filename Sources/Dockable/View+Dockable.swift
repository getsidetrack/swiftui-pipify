//
//  View+Dockable.swift
//  Dockable
//
//  Created by James Sherlock on 01/07/2022.
//

import SwiftUI

public extension View {
    func dockable(controller: DockableController, view: @autoclosure @escaping () -> some View, renderOffscreen: Bool = true) -> some View {
        overlay {
            GeometryReader { proxy in
                LayerView(layer: controller.bufferLayer, size: proxy.size)
                    // layer needs to be in the hierarchy, doesn't actually need to be visible
                    .opacity(0)
                    .allowsHitTesting(false)
                    .offset(renderOffscreen ? .init(width: .max, height: .max) : .zero)
            }
        }
        .onChange(of: controller.enabled) { enabled in
            if enabled {
                controller.start()
            } else {
                controller.stop()
            }
        }
        .task {
            await controller.setView(view())
        }
    }
    
    func dockable(controller: DockableController) -> some View {
        dockable(controller: controller, view: self, renderOffscreen: false)
    }
}

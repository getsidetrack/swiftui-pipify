//
//  View+Dockable.swift
//  Dockable
//
//  Created by James Sherlock on 01/07/2022.
//

import SwiftUI

public extension View {
    func dockable(controller: DockableController, view: @autoclosure @escaping () -> some View) -> some View {
        overlay {
            LayerView(layer: controller.bufferLayer)
                // layer needs to be in the hierarchy, doesn't actually need to be visible
                .opacity(0)
                .allowsHitTesting(false)
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
}

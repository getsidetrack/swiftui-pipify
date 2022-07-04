//
//  Copyright 2022 • Sidetrack Tech Limited
//

import SwiftUI

internal struct PipifyModifier<PipView: View>: ViewModifier {
    @ObservedObject var controller: DockableController
    let pipContent: () -> PipView
    let onPlayPause: ((Bool) -> Void)?
    let offscreenRendering: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if offscreenRendering == false {
                    GeometryReader { proxy in
                        generateLayerView(size: proxy.size)
                    }
                } else {
                    generateLayerView(size: nil)
                }
            }
            .onChange(of: controller.enabled) { newValue in
                if newValue {
                    controller.start()
                } else {
                    controller.stop()
                }
            }
            .onChange(of: controller.isPlaying) { newValue in
                onPlayPause?(newValue)
            }
            .task {
                controller.isPlayPauseEnabled = onPlayPause != nil
                controller.setView(pipContent())
            }
    }
    
    @ViewBuilder
    func generateLayerView(size: CGSize?) -> some View {
        LayerView(layer: controller.bufferLayer, size: size)
            // layer needs to be in the hierarchy, doesn't actually need to be visible
            .opacity(0)
            .allowsHitTesting(false)
            // if we have a size, then we'll morph from the existing view. otherwise we'll fade from offscreen.
            .offset(size != nil ? .zero : .init(width: .max, height: .max))
    }
}


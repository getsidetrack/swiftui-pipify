//
//  Copyright 2022 • Sidetrack Tech Limited
//

import SwiftUI

internal struct PipifyModifier<PipView: View>: ViewModifier {
    @Binding var isPresented: Bool
    @StateObject var controller: PipifyController = PipifyController()
    
    let pipContent: () -> PipView
    let offscreenRendering: Bool
    
    init(
        isPresented: Binding<Bool>,
        pipContent: @escaping () -> PipView,
        offscreenRendering: Bool
    ) {
        self._isPresented = isPresented
        self.pipContent = pipContent
        self.offscreenRendering = offscreenRendering
    }
    
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
            .onChange(of: isPresented) { newValue in
                logger.trace("isPresented changed to \(newValue)")
                if newValue {
                    controller.start()
                } else {
                    controller.stop()
                }
            }
            .onChange(of: controller.enabled) { newValue in
                isPresented = newValue
            }
            .task {
                logger.trace("setting view content")
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


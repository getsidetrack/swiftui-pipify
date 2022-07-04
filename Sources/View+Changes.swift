//
//  Copyright 2022 • Sidetrack Tech Limited
//

import SwiftUI

public extension View {
    func onPipPlayPause(closure: @escaping (Bool) -> Void) -> some View {
        modifier(PipifyPlayPauseModifier(closure: closure))
    }
    
    func onPipStart(closure: @escaping () -> Void) -> some View {
        modifier(PipifyStatusModifier(closure: { newValue in
            if newValue {
                closure()
            }
        }))
    }
    
    func onPipStop(closure: @escaping () -> Void) -> some View {
        modifier(PipifyStatusModifier(closure: { newValue in
            if newValue == false {
                closure()
            }
        }))
    }
    
    func onPipRenderSizeChanged(closure: @escaping (CGSize) -> Void) -> some View {
        modifier(PipifyRenderSizeModifier(closure: closure))
    }
}

internal struct PipifyPlayPauseModifier: ViewModifier {
    @EnvironmentObject var controller: PipifyController
    let closure: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .task {
                controller.isPlayPauseEnabled = true
            }
            .onChange(of: controller.isPlaying) { newValue in
                closure(newValue)
            }
    }
}

internal struct PipifyRenderSizeModifier: ViewModifier {
    @EnvironmentObject var controller: PipifyController
    let closure: (CGSize) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: controller.renderSize) { newValue in
                closure(newValue)
            }
    }
}

internal struct PipifyStatusModifier: ViewModifier {
    @EnvironmentObject var controller: PipifyController
    let closure: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: controller.enabled) { newValue in
                closure(newValue)
            }
    }
}

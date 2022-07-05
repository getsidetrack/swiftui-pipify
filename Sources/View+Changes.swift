//
//  Copyright 2022 • Sidetrack Tech Limited
//

import SwiftUI

public extension View {
    /// When the user uses the play/pause button inside the picture-in-picture window, the provided closure is called.
    ///
    /// The `Bool` is true if playing, else paused.
    func onPipPlayPause(closure: @escaping (Bool) -> Void) -> some View {
        modifier(PipifyPlayPauseModifier(closure: closure))
    }
    
    /// When the user uses the skip forward/backward button inside the picture-in-picture window, the provided closure is called.
    ///
    /// The `Bool` is true if forward, else backwards.
    func onPipSkip(closure: @escaping (Bool) -> Void) -> some View {
        modifier(PipifySkipModifier(closure: closure))
    }
    
    /// When picture-in-picture is started, the provided closure is called.
    func onPipStart(closure: @escaping () -> Void) -> some View {
        modifier(PipifyStatusModifier(closure: { newValue in
            if newValue {
                closure()
            }
        }))
    }
    
    /// When picture-in-picture is stopped, the provided closure is called.
    func onPipStop(closure: @escaping () -> Void) -> some View {
        modifier(PipifyStatusModifier(closure: { newValue in
            if newValue == false {
                closure()
            }
        }))
    }
    
    /// When the render size of the picture-in-picture window is changed, the provided closure is called.
    func onPipRenderSizeChanged(closure: @escaping (CGSize) -> Void) -> some View {
        modifier(PipifyRenderSizeModifier(closure: closure))
    }
    
    /// When the application is moved to the foreground, and if picture-in-picture is active, stop it.
    func pipHideOnForeground() -> some View {
        modifier(PipifyForegroundModifier())
    }
    
    /// When the application is moved to the background, activate picture-in-picture.
    func pipShowOnBackground() -> some View {
        modifier(PipifyBackgroundModifier())
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

internal struct PipifySkipModifier: ViewModifier {
    @EnvironmentObject var controller: PipifyController
    let closure: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .task {
                controller.onSkip = { value in
                    closure(value > 0) // isForward
                }
            }
    }
}

internal struct PipifyBackgroundModifier: ViewModifier {
    @EnvironmentObject var controller: PipifyController
    @Environment(\.scenePhase) var scenePhase
    
    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .background {
                    controller.isPlaying = true
                }
            }
    }
}

internal struct PipifyForegroundModifier: ViewModifier {
    @EnvironmentObject var controller: PipifyController
    @Environment(\.scenePhase) var scenePhase
    
    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    controller.isPlaying = false
                }
            }
    }
}

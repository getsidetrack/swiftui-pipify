//
//  Copyright 2022 • Sidetrack Tech Limited
//

import SwiftUI

public extension View {
    
    /// Creates a Picture in Picture experience when given a SwiftUI view. This allows a view of your application to be presented over the top of the application
    /// window and even when your application is in the background.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a boolean which determines when the Picture in Picture controller should be presented.
    ///   - onPlayPause: A closure which, if provided, is called whenever the user toggles the play/pause button. If no closure is provided (nil), then the pause
    ///   button will always be shown to the user.
    ///   - content: A closure which returns the view you wish to present in the Picture in Picture controller.
    @warn_unqualified_access
    func pipify<PipView: View>(
        controller: DockableController,
        onPlayPause: ((Bool) -> Void)? = nil,
        content: @escaping () -> PipView
    ) -> some View {
        modifier(PipifyModifier(
            controller: controller,
            pipContent: content,
            onPlayPause: onPlayPause,
            offscreenRendering: true
        ))
    }
    
    /// Creates a Picture in Picture experience using the current view. This allows the view to be presented over the top of the application window and even when
    /// your application is in the background.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a boolean which determines when the Picture in Picture controller should be presented.
    ///   - onPlayPause: A closure which, if provided, is called whenever the user toggles the play/pause button. If no closure is provided (nil), then the pause
    ///   button will always be shown to the user.
    @warn_unqualified_access
    func pipify(
        controller: DockableController,
        onPlayPause: ((Bool) -> Void)? = nil
    ) -> some View {
        modifier(PipifyModifier(
            controller: controller,
            pipContent: { self },
            onPlayPause: onPlayPause,
            offscreenRendering: false
        ))
    }
    
}

/// Makes the Pipify view modifier available to Xcode's library allowing for improved auto-complete and discoverability.
///
/// Reference: https://useyourloaf.com/blog/adding-views-and-modifiers-to-the-xcode-library/
struct PipifyLibrary: LibraryContentProvider {
    @StateObject var controller = DockableController()
    
    @LibraryContentBuilder
    func modifiers(base: any View) -> [LibraryItem] {
        LibraryItem(base.pipify(controller: controller), title: "Pipify Embedded View")
        LibraryItem(base.pipify(controller: controller) { Text("Hello, world!") }, title: "Pipify External View")
    }
}

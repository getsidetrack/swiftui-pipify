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
    ///   - content: A closure which returns the view you wish to present in the Picture in Picture controller.
    @warn_unqualified_access
    func pipify<PipView: View>(
        isPresented: Binding<Bool>,
        content: @escaping () -> PipView
    ) -> some View {
        modifier(PipifyModifier(
            isPresented: isPresented,
            pipContent: content,
            offscreenRendering: true
        ))
    }
    
    /// Creates a Picture in Picture experience using the current view. This allows the view to be presented over the top of the application window and even when
    /// your application is in the background.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a boolean which determines when the Picture in Picture controller should be presented.
    @warn_unqualified_access
    func pipify(
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(PipifyModifier(
            isPresented: isPresented,
            pipContent: { self },
            offscreenRendering: false
        ))
    }
    
}

/// Makes the Pipify view modifier available to Xcode's library allowing for improved auto-complete and discoverability.
///
/// Reference: https://useyourloaf.com/blog/adding-views-and-modifiers-to-the-xcode-library/
struct PipifyLibrary: LibraryContentProvider {
    @State var isPresented: Bool = false
    
    @LibraryContentBuilder
    func modifiers(base: any View) -> [LibraryItem] {
        LibraryItem(base.pipify(isPresented: $isPresented), title: "Pipify Embedded View")
        LibraryItem(base.pipify(isPresented: $isPresented) { Text("Hello, world!") }, title: "Pipify External View")
    }
}

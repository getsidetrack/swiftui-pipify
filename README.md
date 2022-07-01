# Dockable

This library introduces a new SwiftUI modifier that enables a view to be shown within a Picture in Picture overlay. This overlay
allows information to be displayed on the screen even when the application is in the background.

This could be great for applications like navigation apps and stock market apps which rely on real-time information being shown
to the user.

> *Note*: This project currently relies on SwiftUI 4 and as such has a minimum deployment target of iOS 16, tvOS 16, or macOS 13 - all of which are currently in beta. This library does not work on watchOS.

## Getting Started

### Installation

We currently support installation through [Swift Package Manager](https://www.swift.org/package-manager/).

```
https://github.com/getsidetrack/swiftui-dockable.git
```

### Project Configuration

You will need to enable "Background Modes" in your project entitlements window. Specifically, you need the 
`Audio, AirPlay and Picture in Picture` option to be enabled. Without this picture in picture mode cannot launch.

### Dockable View

You will need to provide a dockable view to the library - this can be any SwiftUI view but there are some important
information to be aware of:

1. This view will be rendered invisiibly when created, so closures such as `task` and `onAppear` may be called when you don't expect it.
2. Most user interactions are not supported - so buttons, tap gestures, and more will not work.
3. Animations and transitions may result in unexpected behaviour and has not been fully tested.

### Controller and Usage

Within your parent view which is responsible for hosting the picture-in-picture component, you will need to add a variable
storing a `DockableController`.

```swift
@ObservedObject var controller = DockableController()
```

You will then need to add a modifier to your existing parent view. This is where you provide access to your dockable view.

```swift
yourView
    .dockable(controller: controller, view: YourDockableView())
```

To enable/disable the dockable experience, you should mutate the binding on the controller:

```swift
controller.enabled = true // enables PiP
controller.enabled = false // disables PiP
```

> A basic example project is included in the repository. Want to share your own example? Raise a pull request with your examples below. 

## How does this work? 

This library utilises what many may refer to as a "hack" but is essentially a feature in Apple's picture-in-picture mode (PiP).

Picture-in-Picture has been around for quite a while first launching with iOS 9 in 2015 and was later brought to macOS 
10.15 in 2019 and tvOS 14 most recently in 2020. It provides users with the ability to view video content while using
other applications, for example watching a YouTube video while reading tweets.

Dockable expands on this feature by essentially creating a video stream from a SwiftUI view. We take a screenshot of your
view anytime it updates and push this through a series of functions in Apple's AVKit. From these screenshots which we turn
into a video stream, we can launch picture-in-picture mode.

From a user's perspective, the view is docked in a layer above the application. Video controls may be visible and can be
hidden by tapping on them. Users can close the overlay at any time. A pause button can be shown, but does nothing.

There is no reason to believe that any of this breaks Apple's App Store guidelines, but it's definitely not an expected
use case and so developers should proceed with caution.

## Thanks

Credit goes to Akihiro Urushihara with [UIPiPView](https://github.com/uakihir0/UIPiPView) which was the inspiration for building
this SwiftUI component.

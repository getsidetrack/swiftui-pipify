# Pipify for SwiftUI

This library introduces a new SwiftUI modifier that enables a view to be shown within a Picture in Picture overlay. This overlay
allows information to be displayed on the screen even when the application is in the background.

This could be great for applications like navigation apps and stock market apps which rely on real-time information being shown
to the user.

> *Note*: This project currently relies on SwiftUI 4 and as such has a minimum deployment target of iOS 16, tvOS 16, or macOS 13 - all of which are currently in beta. This library does not work on watchOS.

## Getting Started

### Installation

We currently support installation through [Swift Package Manager](https://www.swift.org/package-manager/).

```
https://github.com/getsidetrack/swiftui-pipify.git
```

### Project Configuration

You will need to enable "Background Modes" in your project entitlements window. Specifically, you need the 
`Audio, AirPlay and Picture in Picture` option to be enabled. Without this picture in picture mode cannot launch.

### Pipify View

The "pipify view" is the view which is actually shown within the picture-in-picture window. This can either be the
view which you add the pipify modifier to, or a completely different view.

If you do not provide a custom pipify view, then we will use the view that the modifier was added to. By default this
will use Apple's 'morph' transition which will animate the view into the picture-in-picture controller.

When a custom pipify view is provided, we will render this offscreen which causes picture-in-picture to simply fade in.

Your pipify view can be any SwiftUI view, but there are some important notes to be aware of:

1. This view will be rendered invisibly when created, so closures such as `task` and `onAppear` may be called when you don't expect it.
2. Most user interactions are not supported - so buttons, tap gestures, and more will not work.
3. Animations and transitions may result in unexpected behaviour and has not been fully tested.

### Usage

Simply add the `pipify` modifier to your SwiftUI view. There are two key signatures based on whether you want to provide
your own custom pipify view (see above).

```swift
@State var isPresented = false

var body: some View {
    yourView
        .pipify(isPresented: $isPresented) // presents `yourView` in PIP
        
    // or

    yourView
        .pipify(isPresented: $isPresented) {
            SomeOtherView() // presents `SomeOtherView` in PIP
        }
}
```

In the example above, you can replace `yourView` with whatever you'd like to show. This is your existing code. The state 
binding is what determines when to present the picture in picture window. This API is similar to Apple's own solutions for example with 
[sheet](https://www.hackingwithswift.com/quick-start/swiftui/how-to-present-a-new-view-using-sheets).

If you provide a custom SwiftUI view as your pipify view, then you may choose to add our pipify controller as an environment
object in that separate view ("SomeOtherView" in the example code above).

Note that you cannot use the EnvironmentObject in the view which specifies the pipify modifier.

```swift
@EnvironmentObject var controller: PipifyController
```

This will give you access to certain variables such as the `renderSize` which returns the size of the picture-in-picture
window.

Alternatively, you can attach our custom closures to your view to get informed about key events.

```
yourPipifyView
    .onPipRenderSizeChanged { size in
        // size has changed
    }
```

> A basic example project is included in the repository. Want to share your own example? Raise a pull request with your examples below. 

### Testing

Pipify will not launch on unsupported devices and will return an error in the debug console stating that it could not launch.
You can check whether a device is compatible by using `PipifyController.isSupported` which returns true or false. You may use
this to show or hide the pip option in your application.

**You must test this library on physical devices**. Due to issues in simulators outside of our control, you will see various
inconsistencies, lack of support and other bugs when run on simulators.

## How does this work? 

This library utilises what many may refer to as a "hack" but is essentially a feature in Apple's picture-in-picture mode (PiP).

Picture-in-Picture has been around for quite a while first launching with iOS 9 in 2015 and was later brought to macOS 
10.15 in 2019 and tvOS 14 most recently in 2020. It provides users with the ability to view video content while using
other applications, for example watching a YouTube video while reading tweets.

Pipify expands on this feature by essentially creating a video stream from a SwiftUI view. We take a screenshot of your
view anytime it updates and push this through a series of functions in Apple's AVKit. From these screenshots which we turn
into a video stream, we can launch picture-in-picture mode.

From a user's perspective, the view is moved in a window above the application. Video controls may be visible and can be
hidden by tapping on them. Users can temporarily hide or close the picture-in-picture window at any time.

⚠️ There is no reason to believe that this functionality breaks Apple's App Store guidelines. There are examples of apps
on the App Store which use this functionality ([Example](https://apps.apple.com/us/app/minispeech-live-transcribe/id1576069409)), 
but there has also been cases of apps being rejected for misuse of the API ([Example](https://twitter.com/palmin/status/1440719449468772361)).

We recommend that developers proceed with caution and consider what the best experience is for their users. You may want to explore
ways of implementing sound into your application.

## Thanks

Credit goes to Akihiro Urushihara with [UIPiPView](https://github.com/uakihir0/UIPiPView) which was the inspiration for building
this SwiftUI component.

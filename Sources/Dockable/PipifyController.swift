//
//  Copyright 2022 • Sidetrack Tech Limited
//

import Foundation
import SwiftUI
import AVKit
import Combine

public final class PipifyController: NSObject, ObservableObject, AVPictureInPictureControllerDelegate,
                                       AVPictureInPictureSampleBufferPlaybackDelegate {
    
    @Published public var renderSize: CGSize = .zero
    @Published public var isPlaying: Bool = true
    
    @Binding internal var enabled: Bool
    internal let bufferLayer = AVSampleBufferDisplayLayer()
    internal var isPlayPauseEnabled = false
    private var pipController: AVPictureInPictureController?
    private var rendererSubscriptions = Set<AnyCancellable>()
    private var pipPossibleObservation: NSKeyValueObservation?
    
    /// Updates (if necessary) the iOS audio session.
    ///
    /// Even though we don't play (or yet even support playing) audio, an audio session must be active in order
    /// for picture-in-picture to operate.
    static func setupAudioSession() {
        // not needed on macOS
        #if !os(macOS)
        let session = AVAudioSession.sharedInstance()
        
        // only update if necessary
        if session.category == .soloAmbient || session.mode == .default {
            try? session.setCategory(.playback, mode: .moviePlayback, options: .mixWithOthers)
        }
        #endif
    }
    
    init(isPresented: Binding<Bool>) {
        _enabled = isPresented
        super.init()
        // the audio session must be setup before the pip controller is created
        Self.setupAudioSession()
        setupController()
    }
    
    private func setupController() {
        bufferLayer.frame.size = .init(width: 300, height: 100)
        bufferLayer.videoGravity = .resizeAspect
        
        pipController = AVPictureInPictureController(contentSource: .init(
            sampleBufferDisplayLayer: bufferLayer,
            playbackDelegate: self
        ))
        
        // Combined with a certain time range this makes it so the skip buttons are not visible / interactable.
        pipController?.requiresLinearPlayback = true
        
        pipController?.delegate = self
    }
    
    @MainActor func setView(_ view: some View, maximumUpdatesPerSecond: Double = 30) {
        let modifiedView = view.environmentObject(self)
        let renderer = ImageRenderer(content: modifiedView)
        
        renderer
            .objectWillChange
            // limit the number of times we redraw per second (performance)
            .throttle(for: .init(1.0 / maximumUpdatesPerSecond), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                self?.render(view: modifiedView, using: renderer)
            }
            .store(in: &rendererSubscriptions)
        
        // first draw
        render(view: modifiedView, using: renderer)
    }
    
    // MARK: - Rendering
    
    private func render(view: some View, using renderer: ImageRenderer<some View>) {
        Task {
            do {
                let buffer = try await view.makeBuffer(renderer: renderer)
                render(buffer: buffer)
            } catch {
                print("failed to create buffer: \(error.localizedDescription)")
            }
        }
    }
    
    private func render(buffer: CMSampleBuffer) {
        if bufferLayer.status == .failed {
            bufferLayer.flush()
        }
        
        bufferLayer.enqueue(buffer)
    }
    
    // MARK: - Lifecycle
    
    internal func start() {
        guard let pipController, pipController.isPictureInPictureActive == false else {
            return
        }
        
        #if !os(macOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        
        if pipController.isPictureInPicturePossible {
            pipController.startPictureInPicture()
        } else {
            // not currently possible, so wait until it is.
            let keyPath = \AVPictureInPictureController.isPictureInPicturePossible
            pipPossibleObservation = pipController.observe(keyPath, options: [ .new ]) { [weak self] controller, change in
                if change.newValue ?? false {
                    controller.startPictureInPicture()
                    self?.pipPossibleObservation = nil
                }
            }
        }
    }
    
    internal func stop() {
        guard let pipController else {
            return
        }
        
        pipController.stopPictureInPicture()
        
        #if !os(macOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }
    
    // MARK: - AVPictureInPictureControllerDelegate

    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        enabled = false
    }
    
    public func pictureInPictureControllerShouldProhibitBackgroundAudioPlayback(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        // We do not support audio through the dockable controller, as such we will allow other background audio to
        // continue playing
        return false
    }
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        enabled = false
    }
    
    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        enabled = false
        completionHandler(true)
    }
    
    // MARK: - AVPictureInPictureSampleBufferPlaybackDelegate
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        if isPlayPauseEnabled {
            isPlaying = playing
        }
    }
    
    public func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return isPlayPauseEnabled && isPlaying == false
    }
    
    public func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        // By returning a positive time range in conjunction with enabling `requiresLinearPlayback`
        // PIP will only show the play/pause button and hide the 'Live' label and skip buttons.
        return CMTimeRange(start: .init(value: 1, timescale: 1), end: .init(value: 2, timescale: 1))
    }
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
        renderSize = .init(width: Int(newRenderSize.width), height: Int(newRenderSize.height))
    }
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime) async {
        // Intentionally empty: we do not support skipping
    }
}

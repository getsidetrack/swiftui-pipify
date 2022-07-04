//
//  Copyright 2022 • Sidetrack Tech Limited
//

import Foundation
import SwiftUI
import AVKit
import Combine
import os.log

public final class PipifyController: NSObject, ObservableObject, AVPictureInPictureControllerDelegate,
                                       AVPictureInPictureSampleBufferPlaybackDelegate {
    
    @Published public var renderSize: CGSize = .zero
    @Published public var isPlaying: Bool = true
    
    @Binding internal var enabled: Bool
    internal var isPlayPauseEnabled = false
    internal let bufferLayer = AVSampleBufferDisplayLayer()
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
        logger.info("configuring audio session")
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
        logger.info("creating pip controller")
        
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
                logger.error("failed to create buffer: \(error.localizedDescription)")
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
        guard let pipController else {
            logger.warning("could not start: no controller")
            return
        }
        
        guard pipController.isPictureInPictureActive == false else {
            logger.warning("could not start: already active")
            return
        }
        
        #if !os(macOS)
        logger.info("activating audio session")
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        
        if pipController.isPictureInPicturePossible {
            logger.info("starting picture in picture")
            pipController.startPictureInPicture()
        } else {
            logger.info("waiting for pip to be possible")
            
            // not currently possible, so wait until it is.
            let keyPath = \AVPictureInPictureController.isPictureInPicturePossible
            pipPossibleObservation = pipController.observe(keyPath, options: [ .new ]) { [weak self] controller, change in
                if change.newValue ?? false {
                    logger.info("starting picture in picture")
                    controller.startPictureInPicture()
                    self?.pipPossibleObservation = nil
                }
            }
        }
    }
    
    internal func stop() {
        guard let pipController else {
            logger.warning("could not stop: no controller")
            return
        }
        
        logger.info("stopping picture in picture")
        pipController.stopPictureInPicture()
        
        #if !os(macOS)
        logger.info("deactivating audio session")
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }
    
    // MARK: - AVPictureInPictureControllerDelegate

    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        logger.info("didStart")
    }
    
    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        logger.info("didStop")
        enabled = false
    }
    
    public func pictureInPictureControllerShouldProhibitBackgroundAudioPlayback(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        // We do not support audio through the pipify controller, as such we will allow other background audio to
        // continue playing
        return false
    }
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        logger.error("failed to start: \(error.localizedDescription)")
        enabled = false
    }
    
    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        logger.info("restore UI")
        enabled = false
        completionHandler(true)
    }
    
    // MARK: - AVPictureInPictureSampleBufferPlaybackDelegate
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        if isPlayPauseEnabled {
            logger.info("setPlaying: \(playing)")
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
        logger.info("window resize: \(newRenderSize.width)x\(newRenderSize.height)")
        renderSize = .init(width: Int(newRenderSize.width), height: Int(newRenderSize.height))
    }
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime) async {
        // Intentionally empty: we do not support skipping
    }
}

let logger = Logger(subsystem: "com.getsidetrack.pipify", category: "Pipify")

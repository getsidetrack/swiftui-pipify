//
//  DockableController.swift
//  Dockable
//
//  Created by James Sherlock on 01/07/2022.
//

import Foundation
import SwiftUI
import AVKit
import Combine

public final class DockableController: NSObject, ObservableObject, AVPictureInPictureControllerDelegate,
                                       AVPictureInPictureSampleBufferPlaybackDelegate {
    
    @Published public var enabled: Bool = false
    
    internal let bufferLayer = AVSampleBufferDisplayLayer()
    private var pipController: AVPictureInPictureController?
    private var rendererSubscriptions = Set<AnyCancellable>()
    private var pipPossibleObservation: NSKeyValueObservation?
    
    override public init() {
        super.init()
        setupController()
        
        #if !os(macOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        #endif
    }
    
    private func setupController() {
        bufferLayer.frame.size = .init(width: 300, height: 100)
        bufferLayer.videoGravity = .resizeAspect
        
        pipController = AVPictureInPictureController(contentSource: .init(
            sampleBufferDisplayLayer: bufferLayer,
            playbackDelegate: self
        ))
        
        pipController?.delegate = self
    }
    
    @MainActor func setView(_ view: some View, maximumUpdatesPerSecond: Double = 30) {
        let renderer = ImageRenderer(content: view)
        
        renderer
            .objectWillChange
            // limit the number of times we redraw per second (performance)
            .throttle(for: .init(1.0 / maximumUpdatesPerSecond), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                self?.render(view: view, using: renderer)
            }
            .store(in: &rendererSubscriptions)
        
        // first draw
        render(view: view, using: renderer)
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
    
    func start() {
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
        // We do not support play/pause
    }
    
    public func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        // By returning an infinite time range the PIP controller will treat this as a livestream
        // as such, they will disable skipping and show a 'Live' label which more closely mimics our use case.
        return CMTimeRange(start: .negativeInfinity, end: .positiveInfinity)
    }
    
    public func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        // We do not support play/pause
        return false
    }
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
        // Intentionally empty: we do not currently do anything with the render size
    }
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime) async {
        // Intentionally empty: we do not support skipping
    }
}

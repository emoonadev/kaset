import AVFoundation
import Foundation
import Observation

/// Owns the app's `AVAudioSession`: `.playback` category, activation, and the interruption /
/// route-change handling that the hidden web view cannot do by itself.
@MainActor
@Observable
final class AudioSessionController {
    private(set) var isActive = false
    private(set) var lastEvent = "none"

    private let session = AVAudioSession.sharedInstance()
    private let logger = DiagnosticsLogger.player
    private var observers: [any NSObjectProtocol] = []
    private weak var playerService: PlayerService?
    private var wasPlayingBeforeInterruption = false

    func start(playerService: PlayerService) {
        self.playerService = playerService
        guard self.observers.isEmpty else { return }

        do {
            try self.session.setCategory(.playback, mode: .default, options: [])
            try self.session.setActive(true)
            self.isActive = true
        } catch {
            self.logger.error("Audio session activation failed: \(error.localizedDescription)")
        }

        let center = NotificationCenter.default
        self.observers.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: self.session,
            queue: .main
        ) { [weak self] note in
            let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                .flatMap(AVAudioSession.InterruptionType.init(rawValue:))
            let options = (note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt)
                .map(AVAudioSession.InterruptionOptions.init(rawValue:))
            MainActor.assumeIsolated {
                self?.handleInterruption(type: type, options: options)
            }
        })
        self.observers.append(center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: self.session,
            queue: .main
        ) { [weak self] note in
            let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt)
                .flatMap(AVAudioSession.RouteChangeReason.init(rawValue:))
            MainActor.assumeIsolated {
                self?.handleRouteChange(reason: reason)
            }
        })
    }

    private func handleInterruption(
        type: AVAudioSession.InterruptionType?,
        options: AVAudioSession.InterruptionOptions?
    ) {
        switch type {
        case .began:
            self.lastEvent = "interruption began"
            self.wasPlayingBeforeInterruption = self.playerService?.isPlaying ?? false
        case .ended:
            self.lastEvent = "interruption ended"
            let shouldResume = options?.contains(.shouldResume) ?? false
            try? self.session.setActive(true)
            if shouldResume, self.wasPlayingBeforeInterruption, let playerService = self.playerService {
                Task { await playerService.resume() }
            }
            self.wasPlayingBeforeInterruption = false
        default:
            break
        }
        self.logger.info("Audio session: \(self.lastEvent)")
    }

    private func handleRouteChange(reason: AVAudioSession.RouteChangeReason?) {
        self.lastEvent = "route change \(reason?.rawValue ?? 0)"
        // Headphones unplugged / Bluetooth disconnected: the system expects playback to pause.
        if reason == .oldDeviceUnavailable, self.playerService?.isPlaying == true, let playerService = self.playerService {
            Task { await playerService.pause() }
        }
        self.logger.info("Audio session: \(self.lastEvent)")
    }
}

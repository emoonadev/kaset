import Foundation

// iOS v1 has no video mode (D4). The shared player stack still names these types, so the
// iOS target gets inert stand-ins with the same surface. None of them ever becomes active.

/// Stand-in for the video-mode video model; `YouTubePlayerService.currentVideo` is always nil.
struct YouTubeVideo {
    let id: String
    let title: String
    let channelName: String?
    let duration: TimeInterval?
    let thumbnailURL: URL?
}

@MainActor
final class YouTubePlayerService {
    var playbackWillStart: (() -> Void)?
    private(set) var isPlaying = false
    private(set) var isPlaybackLoading = false
    private(set) var progress: TimeInterval = 0
    private(set) var currentVideo: YouTubeVideo?

    func pause() {}
    func handleRemoteResume(issuedAtMilliseconds _: Double) {}
    func handleRemotePause(issuedAtMilliseconds _: Double) {}
    func handleRemoteTogglePlayPause(issuedAtMilliseconds _: Double) {}
    func handleRemoteSeek(to _: TimeInterval, issuedAtMilliseconds _: Double) {}
    func handleRemoteSkipForward(issuedAtMilliseconds _: Double) async {}
    func handleRemoteSkipBackward(issuedAtMilliseconds _: Double) {}
}

/// Stand-in for the mix tracklist parser (needs the YouTube video client).
@MainActor
final class MixTracklistParser {
    func parseTracklist(videoId _: String) async -> MixTracklist? {
        nil
    }

    func hasCachedResult(for _: String) -> Bool {
        false
    }
}

import Foundation

// MARK: - PlayerServiceProtocol

/// Protocol defining the interface for playback control.
/// Enables dependency injection and mocking for tests.
@MainActor
protocol PlayerServiceProtocol: AnyObject, Sendable {
    /// Current playback state.
    var state: PlayerService.PlaybackState { get }

    /// Currently playing track.
    var currentTrack: Song? { get }

    /// Whether playback is active.
    var isPlaying: Bool { get }

    /// Current playback position in seconds.
    var progress: TimeInterval { get }

    /// Total duration of current track in seconds.
    var duration: TimeInterval { get }

    /// Current volume (0.0 - 1.0).
    var volume: Double { get }

    /// Whether audio is currently muted.
    var isMuted: Bool { get }

    /// Whether shuffle mode is enabled.
    var shuffleEnabled: Bool { get }

    /// Current repeat mode.
    var repeatMode: PlayerService.RepeatMode { get }

    /// Playback queue.
    var queue: [Song] { get }

    /// Queue cursor used for next/previous navigation.
    var currentIndex: Int { get }

    /// Index of the queue entry that actually owns playback, or nil for detached playback.
    var activePlaybackQueueIndex: Int? { get }

    /// Whether the mini player should be shown.
    var showMiniPlayer: Bool { get set }

    /// Whether the native mini player window is visible.
    var isMiniPlayerVisible: Bool { get set }

    /// How the native mini player was opened.
    var miniPlayerMode: PlayerService.MiniPlayerMode { get set }

    /// Active native mini player layout.
    var miniPlayerPanel: PlayerService.MiniPlayerPanel { get set }

    /// Whether closing the mini player should restore the main window.
    var shouldRestoreMainWindowWhenMiniPlayerCloses: Bool { get set }

    /// Like status of the current track.
    var currentTrackLikeStatus: LikeStatus { get }

    /// Whether the current track is in the user's library.
    var currentTrackInLibrary: Bool { get }

    // MARK: - Playback Control

    /// Plays a track by video ID.
    func play(videoId: String) async

    /// Plays a song.
    func play(song: Song) async

    /// Toggles play/pause.
    func playPause() async

    /// Pauses playback.
    func pause() async

    /// Resumes playback.
    func resume() async

    /// Skips to next track.
    func next() async

    /// Goes to previous track.
    func previous() async

    /// Seeks to a specific time.
    func seek(to time: TimeInterval) async

    /// Sets the volume.
    func setVolume(_ value: Double) async

    /// Toggles mute state.
    func toggleMute() async

    /// Toggles shuffle mode.
    func toggleShuffle()

    /// Cycles through repeat modes.
    func cycleRepeatMode()

    /// Opens the native mini player.
    func openMiniPlayer(mode: PlayerService.MiniPlayerMode)

    /// Toggles the native mini player.
    @discardableResult
    func toggleMiniPlayer(mode: PlayerService.MiniPlayerMode) -> Bool

    /// Closes the native mini player.
    @discardableResult
    func closeMiniPlayer() -> Bool

    /// Consumes a pending request to restore the main app window.
    func consumeMiniPlayerMainWindowRestoreRequest() -> Bool

    /// Toggles compact/expanded native mini player layout.
    func toggleMiniPlayerPanel()

    /// Stops playback and clears state.
    func stop() async

    /// Reserves native playback ownership without changing the current intent.
    func reserveMusicPlaybackIntent() -> MusicPlaybackReservation

    /// Claims a reservation only if no newer playback intent has superseded it.
    func claimMusicPlaybackIntent(_ reservation: MusicPlaybackReservation) -> MusicPlaybackIntent?

    /// Whether an unclaimed reservation still names the current playback context.
    func acceptsMusicPlaybackReservation(_ reservation: MusicPlaybackReservation) -> Bool

    /// Captures the queue context for queue-only deferred mutations.
    func reserveQueueMutation() -> Int

    /// Whether a queue-only mutation still targets the same queue context.
    func acceptsQueueMutation(_ generation: Int) -> Bool

    /// Whether the supplied native playback intent still owns mutations.
    func acceptsMusicPlaybackIntent(_ intent: MusicPlaybackIntent) -> Bool

    /// Plays a queue of songs starting at the specified index.
    func playQueue(_ songs: [Song], startingAt index: Int) async

    /// Conditionally plays a queue under a previously claimed native intent.
    @discardableResult
    func playQueue(
        _ songs: [Song],
        startingAt index: Int,
        deferringSmartShuffleFill: Bool,
        intent: MusicPlaybackIntent
    ) async -> Int?

    /// Plays a song and fetches similar songs (radio queue) in the background.
    /// The queue will be populated with similar songs from YouTube Music's radio feature.
    func playWithRadio(song: Song) async

    /// Plays an artist mix from a mix playlist ID.
    /// Starts playing immediately and fetches the full mix queue in the background.
    /// - Parameters:
    ///   - playlistId: The mix playlist ID (e.g., "RDEM...")
    ///   - startVideoId: Optional starting video ID
    func playWithMix(
        playlistId: String,
        startVideoId: String?,
        intent: MusicPlaybackIntent?
    ) async

    /// Clears the queue while preserving the current track when possible.
    func clearQueue()

    /// Shuffles the current queue order.
    func shuffleQueue()

    /// Appends songs to the end of the queue.
    func appendToQueue(_ songs: [Song])

    // MARK: - Like/Library Actions

    /// Likes the current track.
    func likeCurrentTrack()

    /// Dislikes the current track.
    func dislikeCurrentTrack()

    /// Toggles the library status of the current track.
    func toggleLibraryStatus()

    // MARK: - State Updates

    /// Records that the WebView observer has confirmed playback has started.
    func confirmPlaybackStarted()

    /// Called when the mini player is dismissed.
    func miniPlayerDismissed()

    /// Updates playback state from the WebView observer.
    func updatePlaybackState(isPlaying: Bool, progress: Double, duration: Double)

    /// Updates track metadata when track changes.
    func updateTrackMetadata(title: String, artist: String, thumbnailUrl: String, videoId: String?)

    /// Updates the like status from WebView observation.
    func updateLikeStatus(_ status: LikeStatus)
}

extension PlayerServiceProtocol {
    func playWithMix(playlistId: String, startVideoId: String?) async {
        await self.playWithMix(
            playlistId: playlistId,
            startVideoId: startVideoId,
            intent: nil
        )
    }
}

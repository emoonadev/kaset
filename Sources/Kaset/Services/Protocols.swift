import Foundation

// MARK: - WebKitManagerProtocol

/// Protocol defining the interface for WebKit cookie and data management.
/// Enables dependency injection and mocking for tests.
@MainActor
protocol WebKitManagerProtocol: AnyObject, Sendable {
    /// Retrieves all cookies from the HTTP cookie store.
    func getAllCookies() async -> [HTTPCookie]

    /// Gets cookies for a specific domain.
    func getCookies(for domain: String) async -> [HTTPCookie]

    /// Builds a Cookie header string for the given domain.
    func cookieHeader(for domain: String) async -> String?

    /// Retrieves the SAPISID cookie value used for authentication.
    func getSAPISID() async -> String?

    /// Checks if the required authentication cookies exist.
    func hasAuthCookies() async -> Bool

    /// Synchronously persists sign-out intent before asynchronous draining begins.
    @discardableResult
    func invalidateAuthCookieRestoration() -> Bool

    /// Clears only authentication cookies from WebKit and persisted storage.
    /// Returns whether the persisted backup was durably invalidated.
    @discardableResult
    func clearAuthCookies() async -> Bool

    /// Clears all website data (cookies, cache, etc.).
    /// Returns whether the persisted backup was durably invalidated.
    @discardableResult
    func clearAllData() async -> Bool

    /// Forces an immediate backup of all YouTube/Google cookies.
    /// Returns whether the latest snapshot is durably available.
    func forceBackupCookies() async -> Bool

    /// Whether the latest transaction setup failed to restore its prior durable state.
    var loginCookieBackupSetupRequiresCleanup: Bool { get }

    /// Starts a login-cookie transaction before the login WebView can mutate
    /// authentication cookies, preserving the previous restorable archive.
    func beginLoginCookieBackup() async -> CookieBackupTransaction?

    /// Clears live login cookies for reauthentication inside an active login
    /// transaction, leaving the archive for rollback.
    func clearLiveLoginCookies(for transaction: CookieBackupTransaction) async -> Bool

    /// Persists a fresh stable snapshot for the active login transaction while
    /// keeping startup restoration disabled.
    func refreshLoginCookieBackup(_ transaction: CookieBackupTransaction) async -> Bool

    /// Whether this manager and its archive queue still own the transaction.
    func isLoginCookieBackupActive(_ transaction: CookieBackupTransaction) async -> Bool

    /// Whether the current stable login-cookie snapshot differs from the
    /// transaction's pre-login baseline.
    func hasLoginCookieSnapshotChanged(_ transaction: CookieBackupTransaction) async -> Bool

    /// Makes a prepared login-cookie backup eligible for startup restoration.
    @discardableResult
    func commitLoginCookieBackup(
        _ transaction: CookieBackupTransaction
    ) async -> String?

    /// Finishes a committed login transaction after AuthService publishes the
    /// matching authenticated identity.
    @discardableResult
    func finalizeLoginCookieBackup(
        _ transaction: CookieBackupTransaction
    ) async -> String?

    /// Disables restoration for a transaction before account work drains.
    func prepareLoginCookieBackupRollback(
        _ transaction: CookieBackupTransaction
    ) async -> Bool

    /// Restores the prior archive and restoration policy after a cancelled or
    /// superseded login attempt.
    func rollbackLoginCookieBackup(
        _ transaction: CookieBackupTransaction
    ) async -> CookieBackupRollbackResult

    /// Waits for startup restoration, retrying temporary storage failures.
    /// Only a failed restore requires destructive cleanup; unavailability preserves state.
    func waitForInitialCookieRestore() async -> CookieRestoreResult

    /// Logs all authentication-related cookies for debugging.
    func logAuthCookies() async

    /// Switches the shared session's active delegated identity to the account
    /// reached by `signinURL`, verifying via `ytcfg.DATASYNC_ID`. Throws if the
    /// switch cannot be verified.
    func switchSessionIdentity(to signinURL: URL, expectedBrandId: String?) async throws
}

// MARK: - YTMusicClientProtocol

/// Protocol defining the interface for YouTube Music API operations.
/// Enables dependency injection and mocking for tests.
@MainActor
protocol YTMusicClientProtocol: Sendable {
    /// Fetches the home page content (initial sections only for fast display).
    /// A forced refresh bypasses and replaces the scoped Home cache.
    func getHome(forceRefresh: Bool) async throws -> HomeResponse

    /// Fetches the next batch of home sections via continuation.
    func getHomeContinuation() async throws -> [HomeSection]?

    /// Whether more home sections are available to load.
    var hasMoreHomeSections: Bool { get }

    /// Fetches signed-in, account-backed recommendations from the YouTube Music home feed.
    func getPersonalizedRecommendations() async throws -> HomeResponse

    /// Fetches the next batch of signed-in recommendation sections.
    func getPersonalizedRecommendationsContinuation() async throws -> [HomeSection]?

    /// Whether more signed-in recommendation sections are available to load.
    var hasMorePersonalizedRecommendationSections: Bool { get }

    /// Fetches the explore page content (initial sections only for fast display).
    func getExplore() async throws -> HomeResponse

    /// Fetches the next batch of explore sections via continuation.
    func getExploreContinuation() async throws -> [HomeSection]?

    /// Whether more explore sections are available to load.
    var hasMoreExploreSections: Bool { get }

    /// Fetches the charts page content (initial sections only for fast display).
    func getCharts() async throws -> HomeResponse

    /// Fetches the next batch of charts sections via continuation.
    func getChartsContinuation() async throws -> [HomeSection]?

    /// Whether more charts sections are available to load.
    var hasMoreChartsSections: Bool { get }

    /// Fetches the moods and genres page content (initial sections only for fast display).
    func getMoodsAndGenres() async throws -> HomeResponse

    /// Fetches the next batch of moods and genres sections via continuation.
    func getMoodsAndGenresContinuation() async throws -> [HomeSection]?

    /// Whether more moods and genres sections are available to load.
    var hasMoreMoodsAndGenresSections: Bool { get }

    /// Fetches the new releases page content (initial sections only for fast display).
    func getNewReleases() async throws -> HomeResponse

    /// Fetches the next batch of new releases sections via continuation.
    func getNewReleasesContinuation() async throws -> [HomeSection]?

    /// Whether more new releases sections are available to load.
    var hasMoreNewReleasesSections: Bool { get }

    /// Fetches the history page content (initial sections only for fast display).
    func getHistory() async throws -> HomeResponse

    /// Fetches the next batch of history sections via continuation.
    func getHistoryContinuation() async throws -> [HomeSection]?

    /// Whether more history sections are available to load.
    var hasMoreHistorySections: Bool { get }

    /// Fetches the podcasts page content (initial sections only for fast display).
    func getPodcasts() async throws -> [PodcastSection]

    /// Fetches the next batch of podcasts sections via continuation.
    func getPodcastsContinuation() async throws -> [PodcastSection]?

    /// Whether more podcasts sections are available to load.
    var hasMorePodcastsSections: Bool { get }

    /// Fetches details for a podcast show including its episodes.
    func getPodcastShow(browseId: String) async throws -> PodcastShowDetail

    /// Fetches more episodes for a podcast show via continuation.
    func getPodcastEpisodesContinuation(token: String) async throws -> PodcastEpisodesContinuation

    /// Searches for content.
    func search(query: String) async throws -> SearchResponse

    /// Searches for songs only (filtered search, excludes videos/podcasts/episodes).
    func searchSongs(query: String) async throws -> [Song]

    /// Searches for songs only with pagination support.
    func searchSongsWithPagination(query: String) async throws -> SearchResponse

    /// Searches for videos only (filtered search with pagination).
    func searchVideos(query: String) async throws -> SearchResponse

    /// Searches for albums only (filtered search with pagination).
    func searchAlbums(query: String) async throws -> SearchResponse

    /// Searches for artists only (filtered search with pagination).
    func searchArtists(query: String) async throws -> SearchResponse

    /// Searches for profiles only (filtered search with pagination).
    func searchProfiles(query: String) async throws -> SearchResponse

    /// Searches for playlists only (filtered search with pagination).
    func searchPlaylists(query: String) async throws -> SearchResponse

    /// Searches for featured playlists only (YouTube Music curated playlists).
    func searchFeaturedPlaylists(query: String) async throws -> SearchResponse

    /// Searches for community playlists only (user-created playlists).
    func searchCommunityPlaylists(query: String) async throws -> SearchResponse

    /// Searches for podcasts only (podcast shows).
    func searchPodcasts(query: String) async throws -> SearchResponse

    /// Searches for podcast episodes only (filtered search with pagination).
    func searchEpisodes(query: String) async throws -> SearchResponse

    /// Fetches the next batch of search results for an explicit continuation value.
    func getSearchContinuation(token: String) async throws -> SearchResponse

    /// Clears cached continuation/session state when switching accounts.
    func resetSessionStateForAccountSwitch()

    /// Fetches search suggestions for autocomplete.
    func getSearchSuggestions(query: String) async throws -> [SearchSuggestion]

    /// Fetches the user's library playlists.
    func getLibraryPlaylists() async throws -> [Playlist]

    /// Fetches the user's library content including playlists and podcast shows.
    func getLibraryContent() async throws -> PlaylistParser.LibraryContent

    /// Fetches the user's liked songs with pagination support.
    func getLikedSongs() async throws -> LikedSongsResponse

    /// Fetches the next batch of liked songs via continuation.
    /// Returns nil if no more songs are available.
    func getLikedSongsContinuation() async throws -> LikedSongsResponse?

    /// Whether more liked songs are available to load.
    var hasMoreLikedSongs: Bool { get }

    /// Fetches playlist details including tracks with pagination support.
    func getPlaylist(id: String) async throws -> PlaylistTracksResponse

    /// Fetches all tracks for a playlist using the queue endpoint (no pagination needed).
    /// This returns all tracks in a single request, which is more reliable for radio playlists.
    func getPlaylistAllTracks(playlistId: String) async throws -> [Song]

    /// Fetches a batch of playlist tracks using the provided continuation token.
    func getPlaylistContinuation(token: String, requiresAuth: Bool) async throws -> PlaylistContinuationResponse

    /// Fetches artist details including their songs and albums.
    func getArtist(id: String) async throws -> ArtistDetail

    /// Fetches all songs for an artist using the songs browse endpoint.
    func getArtistSongs(browseId: String, params: String?) async throws -> [Song]

    /// Fetches an artist's full discography (`MUSIC_PAGE_TYPE_ARTIST_DISCOGRAPHY`).
    /// Returns every album / single / EP behind an Albums-shelf "See all".
    func getArtistDiscography(browseId: String, params: String?) async throws -> [Album]

    /// Fetches a filtered artist-page subset (`MUSIC_PAGE_TYPE_ARTIST`) — the
    /// full Latest-episodes listing behind the shelf's "See all". The
    /// authenticated response is a single `gridRenderer` of
    /// `musicMultiRowListItemRenderer` items (including live streams), so the
    /// return type is a flat list.
    func getArtistEpisodesList(browseId: String, params: String?) async throws -> [ArtistEpisode]

    /// Rates a song (like/dislike/indifferent).
    func rateSong(videoId: String, rating: LikeStatus) async throws

    /// Adds or removes a song from the user's library.
    func editSongLibraryStatus(feedbackTokens: [String]) async throws

    /// Adds a playlist to the user's library.
    func subscribeToPlaylist(playlistId: String) async throws

    /// Permanently deletes one of the user's own playlists.
    func deletePlaylist(playlistId: String) async throws

    /// Fetches the user's playlists that can receive the provided song.
    func getAddToPlaylistOptions(videoId: String) async throws -> AddToPlaylistMenu

    /// Adds a song to an existing playlist.
    func addSongToPlaylist(videoId: String, playlistId: String, allowDuplicate: Bool) async throws

    /// Removes a song from a playlist.
    /// - Parameter setVideoId: The playlist-item-specific identifier (from `Song.playlistSetVideoId`)
    ///   identifying which occurrence of the song to remove.
    func removeSongFromPlaylist(videoId: String, setVideoId: String, playlistId: String) async throws

    /// Creates a playlist and optionally seeds it with songs.
    func createPlaylist(
        title: String,
        description: String?,
        privacyStatus: PlaylistPrivacyStatus,
        videoIds: [String]
    ) async throws -> String

    /// Removes a playlist from the user's library.
    func unsubscribeFromPlaylist(playlistId: String) async throws

    /// Subscribes to a podcast show (adds to library).
    func subscribeToPodcast(showId: String) async throws

    /// Unsubscribes from a podcast show (removes from library).
    func unsubscribeFromPodcast(showId: String) async throws

    /// Subscribes to an artist (adds to library).
    func subscribeToArtist(channelId: String) async throws

    /// Unsubscribes from an artist (removes from library).
    func unsubscribeFromArtist(channelId: String) async throws

    /// Fetches lyrics for a song.
    func getLyrics(videoId: String) async throws -> Lyrics

    /// Fetches timed (synced) lyrics for a song from YouTube Music.
    /// Returns synced lyrics if available, falls back to plain lyrics, or returns unavailable.
    func getTimedLyrics(videoId: String) async throws -> LyricResult

    /// Fetches song metadata by video ID.
    func getSong(videoId: String) async throws -> Song

    /// Fetches a radio queue (similar songs) based on a video ID.
    /// Returns an array of songs that form a "radio" playlist based on the seed track.
    func getRadioQueue(videoId: String) async throws -> [Song]

    /// Fetches a mix queue from a playlist ID (e.g., artist mix "RDEM...").
    /// - Parameters:
    ///   - playlistId: The mix playlist ID (e.g., "RDEM..." for artist mix)
    ///   - startVideoId: Optional starting video ID
    /// - Returns: RadioQueueResult with songs and continuation token for infinite mix
    func getMixQueue(playlistId: String, startVideoId: String?) async throws -> RadioQueueResult

    /// Fetches more songs for a mix queue using a continuation token.
    /// - Parameter continuationToken: The continuation token from a previous getMixQueue call
    /// - Returns: RadioQueueResult with additional songs and next continuation token
    func getMixQueueContinuation(continuationToken: String) async throws -> RadioQueueResult

    /// Fetches content for a moods/genres category page.
    /// Returns sections of songs/playlists for the category.
    func getMoodCategory(browseId: String, params: String?) async throws -> HomeResponse

    /// Fetches the list of available accounts (primary + brand accounts).
    /// Used for account switching functionality.
    func fetchAccountsList(allowGuestMode: Bool) async throws -> AccountsListResponse
}

extension YTMusicClientProtocol {
    /// Fetches accounts using normal personal-mode authentication.
    func fetchAccountsList() async throws -> AccountsListResponse {
        try await self.fetchAccountsList(allowGuestMode: false)
    }

    /// Fetches a public playlist continuation by default.
    func getPlaylistContinuation(token: String) async throws -> PlaylistContinuationResponse {
        try await self.getPlaylistContinuation(token: token, requiresAuth: false)
    }
}

// MARK: - LoginAttemptID

struct LoginAttemptID: Equatable, Sendable {
    let rawValue: UInt64
}

// MARK: - AuthServiceProtocol

/// Protocol defining the interface for authentication operations.
/// Enables dependency injection and mocking for tests.
@MainActor
protocol AuthServiceProtocol: AnyObject, Sendable {
    /// Current authentication state.
    var state: AuthService.State { get }

    /// Flag indicating whether re-authentication is needed.
    var needsReauth: Bool { get set }

    /// Local identity of the currently presented login attempt.
    var activeLoginAttemptID: LoginAttemptID? { get }

    /// Whether a failed login cleanup must be retried before another sign-in.
    var loginCleanupRequired: Bool { get }

    /// Whether failed-login cleanup still owns the account boundary.
    var isLoginCleanupInProgress: Bool { get }

    /// Changes synchronously whenever an explicit sign-out begins.
    var signOutSequence: UInt64 { get }

    /// Records whether the failed-login cleanup still needs a retry.
    func setLoginCleanupRequired(_ required: Bool)

    /// Starts the login flow by presenting the login sheet.
    func startLogin()

    /// Checks if the user is logged in based on existing cookies.
    func checkLoginStatus() async

    /// Called when a session expires (e.g., 401/403 from API).
    func sessionExpired()

    /// Signs out the user by clearing all cookies and data.
    @discardableResult
    func signOut() async -> Bool

    /// Commits a login after account-scoped work has drained.
    /// Returns false when cancellation, sign-out, or a newer login attempt supersedes it.
    func completeLoginAfterDraining(
        expectedAttemptID: LoginAttemptID,
        persistBeforeCommit: @escaping @MainActor @Sendable () async -> String?,
        persistFinalSession: @escaping @MainActor @Sendable () async -> String?,
        willPublishLogin: @escaping @MainActor @Sendable () -> Void
    ) async -> Bool

    /// Resolves a login-cookie rollback while the account mutation boundary is held.
    func resolveLoginRollbackAfterDraining(
        expectedAttemptID: LoginAttemptID?,
        prepareRollback: @escaping @MainActor @Sendable () async -> Bool,
        rollback: @escaping @MainActor @Sendable (_ forceCleanup: Bool) async -> CookieBackupRollbackResult
    ) async -> CookieBackupRollbackResult

    /// Fences and drains a published or pending login before cookie cleanup,
    /// then applies the cleanup result only while that boundary remains current.
    func clearFailedLoginAfterDraining(
        expectedAttemptID: LoginAttemptID,
        expectedSignOutSequence: UInt64,
        clearCookies: @escaping @MainActor @Sendable () async -> Bool
    ) async -> Bool?
}

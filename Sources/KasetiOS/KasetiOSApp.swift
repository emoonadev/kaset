import SwiftUI

/// Entry point of the Kaset iOS app.
///
/// Until the real shell lands (S7), the app hosts the playback lab so background playback
/// can be verified on device (S4).
@main
struct KasetiOSApp: App {
    @State private var authService: AuthService
    @State private var webKitManager: WebKitManager
    @State private var playerService: PlayerService
    @State private var audioSession = AudioSessionController()

    init() {
        let auth = AuthService()
        let webkit = WebKitManager.shared
        let player = PlayerService()
        let client = YTMusicClient(authService: auth, webKitManager: webkit)
        player.setYTMusicClient(client)
        player.setAuthService(auth)
        PlayerService.shared = player

        _authService = State(initialValue: auth)
        _webKitManager = State(initialValue: webkit)
        _playerService = State(initialValue: player)
    }

    var body: some Scene {
        WindowGroup {
            PlayerLabView()
                .environment(self.authService)
                .environment(self.webKitManager)
                .environment(self.playerService)
                .environment(self.audioSession)
                .task {
                    self.audioSession.start(playerService: self.playerService)
                }
        }
    }
}

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
    @State private var accountService: AccountService
    @State private var audioSession = AudioSessionController()

    init() {
        let auth = AuthService()
        let webkit = WebKitManager.shared
        let player = PlayerService()
        let client = YTMusicClient(authService: auth, webKitManager: webkit)
        player.setYTMusicClient(client)
        player.setAuthService(auth)
        PlayerService.shared = player

        let account = AccountService(ytMusicClient: client, authService: auth, webKitManager: webkit)
        client.brandIdProvider = { [weak account] in
            account?.currentBrandId
        }
        client.accountScopeProvider = { [weak account] in
            account?.currentAccountScopeID
        }

        _authService = State(initialValue: auth)
        _webKitManager = State(initialValue: webkit)
        _playerService = State(initialValue: player)
        _accountService = State(initialValue: account)
    }

    var body: some Scene {
        WindowGroup {
            PlayerLabView()
                .environment(self.authService)
                .environment(self.webKitManager)
                .environment(self.playerService)
                .environment(self.accountService)
                .environment(self.audioSession)
                .task {
                    self.audioSession.start(playerService: self.playerService)
                }
                .task(id: self.authService.startupState) {
                    // Same startup contract as KasetApp: restore the session from the cookie
                    // archive, then load the account list once the login state is resolved.
                    guard let startupState = self.authService.startupState else { return }
                    let signOutSequence = self.authService.signOutSequence
                    guard await self.authService.checkLoginStatusForStartup(expectedState: startupState),
                          !Task.isCancelled,
                          self.authService.startupState == startupState,
                          self.authService.signOutSequence == signOutSequence
                    else { return }
                    self.accountService.authenticationIdentityDidChange()
                    await self.accountService.fetchAccounts()
                }
        }
    }
}

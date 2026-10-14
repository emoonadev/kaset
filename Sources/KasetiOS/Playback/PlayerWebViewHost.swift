import SwiftUI
import WebKit

/// Mounts the shared playback web view as a hidden 1×1 anchor, like `PersistentPlayerView` on macOS.
/// The page keeps playing with the screen locked (docs/ios/spike-findings.md).
struct PlayerWebViewHost: UIViewRepresentable {
    @Environment(WebKitManager.self) private var webKitManager
    @Environment(PlayerService.self) private var playerService
    @Environment(AuthService.self) private var authService

    let videoId: String?

    func makeUIView(context _: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.isUserInteractionEnabled = false
        self.mount(in: container)
        return container
    }

    func updateUIView(_ container: UIView, context _: Context) {
        self.mount(in: container)
    }

    private func mount(in container: UIView) {
        let webView = SingletonPlayerWebView.shared.getWebView(
            webKitManager: self.webKitManager,
            playerService: self.playerService,
            usesCookieFreeDataStore: self.authService.shouldUseCookieFreePlaybackDataStore
        )

        if webView.superview !== container {
            webView.removeFromSuperview()
            webView.frame = container.bounds
            webView.autoresizingMask = PlatformView.fillAutoresizing
            container.addSubview(webView)
        } else {
            webView.frame = container.bounds
        }

        if let videoId = self.videoId,
           self.playerService.shouldAutoloadPendingVideo,
           SingletonPlayerWebView.shared.currentVideoId != videoId
        {
            SingletonPlayerWebView.shared.loadVideo(videoId: videoId)
        }
    }
}

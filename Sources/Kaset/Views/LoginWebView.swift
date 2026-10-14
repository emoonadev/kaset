import SwiftUI
import WebKit

/// WebView for Google login.
#if os(macOS)
    private typealias LoginWebViewRepresentable = NSViewRepresentable
#else
    private typealias LoginWebViewRepresentable = UIViewRepresentable
#endif

struct LoginWebView: LoginWebViewRepresentable {
    @Environment(WebKitManager.self) private var webKitManager

    /// Callback when navigation completes to YouTube Music.
    var onNavigationToYouTubeMusic: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onNavigationToYouTubeMusic: self.onNavigationToYouTubeMusic)
    }

    #if os(macOS)
        func makeNSView(context: Context) -> WKWebView {
            self.makeLoginWebView(context: context)
        }

        func updateNSView(_: WKWebView, context _: Context) {
            // No updates needed
        }
    #else
        func makeUIView(context: Context) -> WKWebView {
            self.makeLoginWebView(context: context)
        }

        func updateUIView(_: WKWebView, context _: Context) {
            // No updates needed
        }
    #endif

    private func makeLoginWebView(context: Context) -> WKWebView {
        let configuration = self.webKitManager.createSessionSwitchWebViewConfiguration()
        #if os(iOS)
            // Google rejects the desktop UA used for playback ("Something went wrong"); the default
            // iOS WebKit UA plus the Mobile Safari suffix signs in. Cookies are shared through the
            // persistent data store, so playback keeps working with its own UA (spike findings §4).
            configuration.applicationNameForUserAgent = "Version/17.0 Mobile/15E148 Safari/604.1"
        #endif
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        #if os(macOS)
            webView.customUserAgent = WebKitManager.userAgent
        #endif
        #if DEBUG
            webView.isInspectable = true
        #endif

        // Load YouTube Music login page
        if let url = URL(string: "https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https%3A%2F%2Fwww.youtube.com%2Fsignin%3Faction_handle_signin%3Dtrue%26app%3Ddesktop%26hl%3Den%26next%3Dhttps%253A%252F%252Fmusic.youtube.com%252F") {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        var onNavigationToYouTubeMusic: (() -> Void)?

        init(onNavigationToYouTubeMusic: (() -> Void)?) {
            self.onNavigationToYouTubeMusic = onNavigationToYouTubeMusic
        }

        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            // Check if we've navigated to YouTube Music
            if let url = webView.url,
               url.host?.contains("music.youtube.com") == true
            {
                self.onNavigationToYouTubeMusic?()
            }
        }
    }
}

#Preview {
    LoginWebView()
        .environment(WebKitManager.shared)
        .frame(width: 500, height: 600)
}

import SwiftUI
import YouTubeAskCore // Linked to prove the shared package builds for iOS; it exposes no public API yet.

/// Entry point of the Kaset iOS app.
///
/// Step S1 of the iOS port only proves that the target builds and links the shared
/// `YouTubeAskCore` library. The real shell arrives in step S7.
@main
struct KasetiOSApp: App {
    var body: some Scene {
        WindowGroup {
            PlaceholderView()
        }
    }
}

private struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 48))
            Text("Kaset")
                .font(.largeTitle.bold())
            Text("iOS port — step S1")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

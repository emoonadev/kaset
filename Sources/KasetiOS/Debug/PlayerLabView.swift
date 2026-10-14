import SwiftUI

/// Debug-only playback bench (S4): enter a video id, play, next/previous, watch live state.
/// Replaced by the real shell in S7.
struct PlayerLabView: View {
    @Environment(PlayerService.self) private var playerService
    @Environment(AudioSessionController.self) private var audioSession

    @State private var videoId = "dQw4w9WgXcQ"

    var body: some View {
        NavigationStack {
            Form {
                Section("Track") {
                    TextField("Video id", text: self.$videoId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Play") {
                        Task { await self.playerService.play(videoId: self.videoId) }
                    }
                }

                Section("Controls") {
                    HStack(spacing: 24) {
                        Button("Previous", systemImage: "backward.fill") {
                            Task { await self.playerService.previous() }
                        }
                        Button(
                            self.playerService.isPlaying ? "Pause" : "Resume",
                            systemImage: self.playerService.isPlaying ? "pause.fill" : "play.fill"
                        ) {
                            Task { await self.playerService.playPause() }
                        }
                        Button("Next", systemImage: "forward.fill") {
                            Task { await self.playerService.next() }
                        }
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                }

                Section("State") {
                    LabeledContent("State", value: String(describing: self.playerService.state))
                    LabeledContent("Title", value: self.playerService.currentTrack?.title ?? "—")
                    LabeledContent("Position", value: "\(Int(self.playerService.progress)) / \(Int(self.playerService.duration)) s")
                    LabeledContent("Queue", value: "\(self.playerService.queue.count)")
                    LabeledContent("Audio session", value: self.audioSession.isActive ? "active" : "inactive")
                    LabeledContent("Last audio event", value: self.audioSession.lastEvent)
                }
            }
            .navigationTitle("Playback lab")
        }
        .background {
            PlayerWebViewHost(videoId: self.playerService.pendingPlayVideoId)
                .frame(width: 1, height: 1)
                .opacity(0)
                .allowsHitTesting(false)
        }
    }
}

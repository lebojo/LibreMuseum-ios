import SwiftUI

struct AudioGuideView: View {
    @Environment(\.mediaStore) private var mediaStore
    @Environment(MuseumTheme.self) private var theme

    @State private var player = AudioGuidePlayer()
    @State private var scrubbedTime: Double?

    let path: String
    var announcedDuration: Int = 0

    private var duration: TimeInterval {
        player.duration > 0 ? player.duration : TimeInterval(announcedDuration)
    }

    private var elapsed: TimeInterval {
        scrubbedTime ?? player.currentTime
    }

    private var elapsedLabel: String {
        Self.timeLabel(elapsed)
    }

    private var remainingLabel: String {
        Self.timeLabel(max(duration - elapsed, 0))
    }

    private var scrubbing: Binding<Double> {
        Binding(
            get: { elapsed },
            set: { scrubbedTime = $0 }
        )
    }

    var body: some View {
        Group {
            switch player.phase {
            case .idle, .loading:
                HStack(spacing: 12) {
                    ProgressView().controlSize(.small)
                    Text("Loading the audio guide")
                        .font(.museumCaption)
                        .foregroundStyle(.secondary)
                }
            case .unavailable:
                Label("Audio guide unavailable offline", systemImage: "speaker.slash")
                    .font(.museumCaption)
                    .foregroundStyle(.secondary)
            case .ready:
                HStack(spacing: 16) {
                    Button {
                        player.togglePlayback()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(theme.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

                    VStack(spacing: 2) {
                        Slider(value: scrubbing, in: 0...max(duration, 1)) { isEditing in
                            guard !isEditing, let scrubbedTime else { return }
                            player.seek(to: scrubbedTime)
                            self.scrubbedTime = nil
                        }
                        .tint(theme.accent)

                        HStack {
                            Text(elapsedLabel)
                            Spacer()
                            Text("-\(remainingLabel)")
                        }
                        .font(.museumCaption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task(id: path) { await player.prepare(path: path, using: mediaStore) }
    }

    private static func timeLabel(_ time: TimeInterval) -> String {
        Duration.seconds(time.rounded()).formatted(.time(pattern: .minuteSecond))
    }
}

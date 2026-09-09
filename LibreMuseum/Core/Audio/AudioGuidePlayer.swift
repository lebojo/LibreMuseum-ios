import AVFoundation
import Foundation

@Observable
@MainActor
final class AudioGuidePlayer {
    enum Phase: Equatable {
        case idle
        case loading
        case ready
        case unavailable
    }

    private(set) var phase: Phase = .idle
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var progressTicker: Task<Void, Never>?
    private var preparedPath = ""

    func prepare(path: String, using mediaStore: MediaStore?) async {
        guard !path.isEmpty, let mediaStore else {
            preparedPath = path
            phase = .unavailable
            return
        }
        guard path != preparedPath else { return }

        stop()
        preparedPath = path
        phase = .loading

        guard let data = await mediaStore.cachedOrDownloadedData(for: path),
              let player = try? AVAudioPlayer(data: data)
        else {
            phase = .unavailable
            return
        }

        player.prepareToPlay()
        self.player = player
        duration = player.duration
        currentTime = 0
        phase = .ready
    }

    func togglePlayback() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            progressTicker?.cancel()
        } else {
            SpokenAudioSession.activate()
            player.play()
            isPlaying = true
            startTickingProgress()
        }
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        player.currentTime = min(max(time, 0), player.duration)
        currentTime = player.currentTime
    }

    func skip(by interval: TimeInterval) {
        guard let player else { return }
        seek(to: player.currentTime + interval)
    }

    func stop() {
        progressTicker?.cancel()
        progressTicker = nil
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        phase = .idle
    }

    private func startTickingProgress() {
        progressTicker?.cancel()
        progressTicker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, self.refreshedProgressIsOngoing() else { return }
            }
        }
    }

    private func refreshedProgressIsOngoing() -> Bool {
        guard let player, isPlaying else { return false }
        guard player.isPlaying else {
            isPlaying = false
            currentTime = 0
            player.currentTime = 0
            return false
        }
        currentTime = player.currentTime
        return true
    }
}

import AVFoundation
import Foundation

@Observable
@MainActor
final class ReadAloudSpeaker {
    enum Phase: Equatable {
        case idle
        case preparing
        case speaking
        case paused
    }

    private(set) var phase: Phase = .idle

    private var synthesizer: AVSpeechSynthesizer?
    private var speechTicker: Task<Void, Never>?
    private var speechStartDeadline: ContinuousClock.Instant?

    var isSpeaking: Bool { phase == .speaking }

    func togglePlayback(of text: String, spokenIn languageCode: String) {
        guard !text.isEmpty else { return }

        switch phase {
        case .preparing: stop()
        case .speaking: pause()
        case .paused: resume()
        case .idle: speak(text, spokenIn: languageCode)
        }
    }

    func stop() {
        speechTicker?.cancel()
        speechTicker = nil
        speechStartDeadline = nil
        synthesizer?.stopSpeaking(at: .immediate)
        phase = .idle
    }

    private func speak(_ text: String, spokenIn languageCode: String) {
        SpokenAudioSession.activate()

        let synthesizer = synthesizer ?? AVSpeechSynthesizer()
        self.synthesizer = synthesizer
        speechStartDeadline = ContinuousClock.now + .seconds(2)
        synthesizer.speak(Self.utterance(of: text, spokenIn: languageCode))

        phase = .preparing
        startTickingSpeech()
    }

    private func pause() {
        speechTicker?.cancel()
        synthesizer?.pauseSpeaking(at: .word)
        phase = .paused
    }

    private func resume() {
        SpokenAudioSession.activate()
        synthesizer?.continueSpeaking()
        phase = .speaking
        startTickingSpeech()
    }

    private func startTickingSpeech() {
        speechTicker?.cancel()
        speechTicker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, self.refreshedSpeechIsOngoing() else { return }
            }
        }
    }

    private func refreshedSpeechIsOngoing() -> Bool {
        guard phase == .preparing || phase == .speaking, let synthesizer else { return false }

        guard synthesizer.isSpeaking else {
            guard let deadline = speechStartDeadline, ContinuousClock.now < deadline else {
                phase = .idle
                return false
            }
            return true
        }

        speechStartDeadline = nil
        phase = .speaking
        return true
    }

    private static func utterance(of text: String, spokenIn languageCode: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voiceMatching(languageCode)
        return utterance
    }

    private static func voiceMatching(_ languageCode: String) -> AVSpeechSynthesisVoice? {
        guard !languageCode.isEmpty,
              let requested = baseLanguage(of: languageCode)
        else { return nil }

        let candidates = AVSpeechSynthesisVoice.speechVoices().filter {
            baseLanguage(of: $0.language) == requested
        }
        let best = candidates.max {
            preference(for: $0, matching: languageCode) < preference(for: $1, matching: languageCode)
        }
        return best ?? AVSpeechSynthesisVoice(language: languageCode)
    }

    private static func preference(
        for voice: AVSpeechSynthesisVoice,
        matching languageCode: String
    ) -> (Int, Int, Int) {
        let spoken = languageWithLikelyRegion(of: voice.language)
        let speaksExpectedRegion = spoken == languageWithLikelyRegion(of: languageCode)
        let speaksDeviceRegion = Locale.preferredLanguages.contains {
            languageWithLikelyRegion(of: $0) == spoken
        }
        return (voice.quality.rawValue, speaksExpectedRegion ? 1 : 0, speaksDeviceRegion ? 1 : 0)
    }

    private static func languageWithLikelyRegion(of identifier: String) -> String {
        Locale.Language(identifier: identifier).maximalIdentifier
    }

    private static func baseLanguage(of identifier: String) -> String? {
        Locale(identifier: identifier).language.languageCode?.identifier
    }
}

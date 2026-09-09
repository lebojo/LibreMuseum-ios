import Foundation

@Observable
@MainActor
final class TicketStore {
    private static let storageKey = "tickets.unlockedUntil"
    private static let fallbackValidityHours = 24

    private let defaults: UserDefaults
    private var unlockedUntil: [String: Date]
    private var expiryTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        unlockedUntil = Self.stored(in: defaults)
        dropExpired()
    }

    func isUnlocked(exhibitionID: String) -> Bool {
        guard let deadline = unlockedUntil[exhibitionID] else { return false }
        return deadline > .now
    }

    func unlockedUntil(exhibitionID: String) -> Date? {
        guard let deadline = unlockedUntil[exhibitionID], deadline > .now else { return nil }
        return deadline
    }

    // A museum that never published `ticket_validity_hours`, or whose record has
    // not synced yet, hands over a zero: one scan would then unlock for good.
    func unlock(exhibitionID: String, forHours hours: Int) {
        let validityHours = hours > 0 ? hours : Self.fallbackValidityHours
        unlockedUntil[exhibitionID] = Date.now.addingTimeInterval(TimeInterval(validityHours) * 3600)
        persist()
        scheduleNextExpiry()
    }

    private func dropExpired() {
        let now = Date.now
        let live = unlockedUntil.filter { $0.value > now }
        if live.count != unlockedUntil.count {
            unlockedUntil = live
            persist()
        }
        scheduleNextExpiry()
    }

    // A deadline that passes while the app is open must relock the screen the
    // visitor is looking at. Nothing else would notice it: no query changes and
    // no request is made, so we wake up exactly once, at the earliest deadline.
    private func scheduleNextExpiry() {
        expiryTask?.cancel()
        expiryTask = nil

        guard let next = unlockedUntil.values.min() else { return }
        let delay = next.timeIntervalSinceNow
        guard delay > 0 else { return dropExpired() }

        expiryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.dropExpired()
        }
    }

    private func persist() {
        let seconds = unlockedUntil.mapValues(\.timeIntervalSince1970)
        defaults.set(seconds, forKey: Self.storageKey)
    }

    // Deliberately not in SwiftData: `purgeAll` empties the content cache, and a
    // visitor who has paid must not lose their unlock by freeing some space.
    private static func stored(in defaults: UserDefaults) -> [String: Date] {
        let seconds = defaults.dictionary(forKey: storageKey) as? [String: Double] ?? [:]
        return seconds.mapValues { Date(timeIntervalSince1970: $0) }
    }
}

import Foundation

nonisolated struct ExhibitionUI: Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let searchableTitles: [String]
    let subtitle: String
    let coverPath: String
    let isPermanent: Bool
    let startDate: Date?
    let endDate: Date?
    let dateRange: String?
    let hasTranslation: Bool
    let requiresTicket: Bool
    let isLocked: Bool

    var hasEnded: Bool {
        guard !isPermanent, let endDate else { return false }
        return endDate < .now
    }

    static func newestStartFirst(_ lhs: ExhibitionUI, _ rhs: ExhibitionUI) -> Bool {
        (lhs.startDate ?? .distantFuture) > (rhs.startDate ?? .distantFuture)
    }

    static func newestEndFirst(_ lhs: ExhibitionUI, _ rhs: ExhibitionUI) -> Bool {
        (lhs.endDate ?? .distantPast) > (rhs.endDate ?? .distantPast)
    }
}

nonisolated struct ExhibitionDetailUI: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let summary: String
    let coverPath: String
    let isPermanent: Bool
    let dateRange: String?
    let audioPath: String
    let hasTranslation: Bool
    let requiresTicket: Bool
    let isLocked: Bool
    let unlockCode: String
    let unlockedUntil: Date?

    // The audio introduction is part of what the ticket pays for: only the
    // written description stays readable from outside.
    var hasAudioGuide: Bool { !audioPath.isEmpty && !isLocked }
}

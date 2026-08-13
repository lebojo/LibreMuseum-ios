import Foundation

nonisolated struct ExhibitionUI: Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let coverPath: String
    let isPermanent: Bool
    let dateRange: String?
    let hasTranslation: Bool
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

    var hasAudioGuide: Bool { !audioPath.isEmpty }
}

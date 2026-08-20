import Foundation

nonisolated struct ExhibitionUI: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let coverPath: String
    let isPermanent: Bool
    let dateRange: String?
    let hasTranslation: Bool
}

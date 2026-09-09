import Foundation

nonisolated struct MuseumUI: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let subtitle: String
    let logoPath: String
    let coverPath: String
}

import Foundation

nonisolated struct LanguageUI: Identifiable, Sendable, Equatable {
    let id: String
    let code: String
    let label: String
}

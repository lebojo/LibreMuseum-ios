import Foundation

nonisolated struct LanguageContext: Sendable, Equatable {
    let displayCode: String
    let museumDefaultCode: String

    static let undetermined = LanguageContext(displayCode: "", museumDefaultCode: "")
}

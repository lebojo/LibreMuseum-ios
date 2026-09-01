import Foundation

nonisolated enum ArtworkSearch {
    struct Fields: Sendable {
        let code: String
        let titles: [String]
        let artist: String
    }

    enum Relevance: Int, Comparable, Sendable {
        case exactCode
        case titlePrefix
        case titleContains
        case artistContains

        static func < (lhs: Relevance, rhs: Relevance) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    static func relevance(of fields: Fields, for query: String) -> Relevance? {
        let needle = comparable(query)
        guard !needle.isEmpty else { return nil }

        if !fields.code.isEmpty, comparable(fields.code) == needle { return .exactCode }

        let titles = fields.titles.map(comparable)
        if titles.contains(where: { $0.hasPrefix(needle) }) { return .titlePrefix }
        if titles.contains(where: { $0.contains(needle) }) { return .titleContains }
        if comparable(fields.artist).contains(needle) { return .artistContains }
        return nil
    }

    static func matches(_ haystack: String, query: String) -> Bool {
        let needle = comparable(query)
        guard !needle.isEmpty else { return false }
        return comparable(haystack).contains(needle)
    }

    static func matches(_ haystacks: [String], query: String) -> Bool {
        haystacks.contains { matches($0, query: query) }
    }

    private static func comparable(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}

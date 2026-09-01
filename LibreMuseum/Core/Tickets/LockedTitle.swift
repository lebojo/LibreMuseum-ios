import Foundation

nonisolated enum LockedTitle {
    private static let tooShortToTease = 4
    private static let shortest = 2
    private static let longest = 5

    // A hint of the title: enough to tell two artworks apart and to want the
    // rest, never enough to read it — hence the quarter and the hard cap. A
    // title of four characters or fewer has no hint to give that would not be
    // the title, so it is hidden whole. The cut is deliberately mid-word: a
    // title cut on a word boundary reads as a title, not as a teaser.
    static func teaser(of title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > tooShortToTease else { return "…" }

        let wanted = min(longest, max(shortest, trimmed.count / 4))
        let kept = min(wanted, trimmed.count - 1)
        let prefix = trimmed.prefix(kept).trimmingCharacters(in: .whitespaces)
        return prefix + "…"
    }
}

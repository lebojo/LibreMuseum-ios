import Foundation

nonisolated enum PocketBaseDate {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        return formatter
    }()

    static func date(from raw: String) -> Date? {
        guard !raw.isEmpty else { return nil }
        return formatter.date(from: raw)
    }
}

import Foundation

nonisolated extension KeyedDecodingContainer {
    func stringOrEmpty(_ key: Key) -> String {
        (try? decodeIfPresent(String.self, forKey: key)) ?? ""
    }

    func stringsOrEmpty(_ key: Key) -> [String] {
        (try? decodeIfPresent([String].self, forKey: key)) ?? []
    }

    func intOrZero(_ key: Key) -> Int {
        (try? decodeIfPresent(Int.self, forKey: key)) ?? 0
    }

    func doubleOrZero(_ key: Key) -> Double {
        (try? decodeIfPresent(Double.self, forKey: key)) ?? 0
    }

    func boolOrFalse(_ key: Key) -> Bool {
        (try? decodeIfPresent(Bool.self, forKey: key)) ?? false
    }

    func dateOrNil(_ key: Key) -> Date? {
        PocketBaseDate.date(from: stringOrEmpty(key))
    }
}

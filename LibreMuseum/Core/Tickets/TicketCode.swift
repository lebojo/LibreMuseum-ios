import Foundation

nonisolated enum TicketCode {
    static func matches(scannedPayload payload: String, unlockCode code: String) -> Bool {
        let expected = comparable(code)
        guard !expected.isEmpty else { return false }
        return candidates(in: payload).contains { comparable($0) == expected }
    }

    // The museum prints whatever its QR generator produced. Most write the code
    // itself, some wrap it in a URL: we accept the payload as it comes, and the
    // last path component and every query value of a URL that carries one.
    private static func candidates(in payload: String) -> [String] {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        var found = [trimmed]

        guard let components = URLComponents(string: trimmed), components.scheme != nil else {
            return found
        }
        found.append(contentsOf: components.path.split(separator: "/").map(String.init))
        found.append(contentsOf: components.queryItems?.compactMap(\.value) ?? [])
        return found
    }

    private static func comparable(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}

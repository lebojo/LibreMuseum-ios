import Foundation

nonisolated enum APIError: Error, Sendable, Equatable {
    case invalidURL
    case offline
    case http(status: Int, message: String)
    case decoding(String)

    var isContentRemovedFromServer: Bool {
        guard case .http(let status, _) = self else { return false }
        return status == 404 || status == 403
    }
}

nonisolated extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            String(localized: "The server address is invalid.")
        case .offline:
            String(localized: "The museum is unreachable. Content already downloaded stays available.")
        case .http(let status, let message):
            message.isEmpty ? String(localized: "The server answered \(status).") : message
        case .decoding(let detail):
            String(localized: "Unexpected answer from the server: \(detail)")
        }
    }
}

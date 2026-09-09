import Foundation

nonisolated protocol PocketBaseClientProtocol: Sendable {
    func list<Item: Decodable & Sendable>(
        _ collection: PocketBaseCollection,
        query: PocketBaseQuery
    ) async throws -> PocketBaseListResponse<Item>

    func record<Item: Decodable & Sendable>(
        _ collection: PocketBaseCollection,
        id: String,
        query: PocketBaseQuery
    ) async throws -> Item

    func contentVersion() async throws -> String

    func media(path: String, thumb: ThumbSize?) async throws -> Data
}

actor PocketBaseClient: PocketBaseClientProtocol {
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession? = nil) {
        self.session = session ?? Self.makeSession()
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default

        configuration.timeoutIntervalForRequest = 15
        configuration.waitsForConnectivity = false

        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }

    func list<Item: Decodable & Sendable>(
        _ collection: PocketBaseCollection,
        query: PocketBaseQuery
    ) async throws -> PocketBaseListResponse<Item> {
        let url = try makeURL(
            path: "/api/collections/\(collection.rawValue)/records",
            queryItems: query.queryItems
        )
        return try await fetchDecoded(url)
    }

    func record<Item: Decodable & Sendable>(
        _ collection: PocketBaseCollection,
        id: String,
        query: PocketBaseQuery
    ) async throws -> Item {
        let url = try makeURL(
            path: "/api/collections/\(collection.rawValue)/records/\(id)",
            queryItems: query.queryItems
        )
        return try await fetchDecoded(url)
    }

    func contentVersion() async throws -> String {
        let url = try makeURL(path: "/api/app/version", queryItems: [])
        let response: ContentVersionResponse = try await fetchDecoded(url)
        return response.version
    }

    func media(path: String, thumb: ThumbSize?) async throws -> Data {
        guard let url = APIConfiguration.mediaURL(path: path, thumb: thumb) else {
            throw APIError.invalidURL
        }
        return try await fetchData(url)
    }

    private func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(
            url: APIConfiguration.baseURL,
            resolvingAgainstBaseURL: false
        ) else { throw APIError.invalidURL }

        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else { throw APIError.invalidURL }
        return url
    }

    private func fetchData(_ url: URL) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let error as URLError {
            throw Self.mapTransportError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.decoding("Non-HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(
                status: http.statusCode,
                message: Self.errorMessage(from: data)
            )
        }
        return data
    }

    private func fetchDecoded<Value: Decodable & Sendable>(_ url: URL) async throws -> Value {
        let data = try await fetchData(url)
        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    private static func mapTransportError(_ error: URLError) -> APIError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost,
             .cannotFindHost, .timedOut, .dataNotAllowed, .internationalRoamingOff:
            .offline
        default:
            .http(status: error.errorCode, message: error.localizedDescription)
        }
    }

    private static func errorMessage(from data: Data) -> String {
        guard let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) else {
            return ""
        }
        return envelope.message ?? ""
    }

    private struct ContentVersionResponse: Decodable, Sendable {
        let version: String
    }

    private struct ErrorEnvelope: Decodable, Sendable {
        let status: Int?
        let code: Int?
        let message: String?
    }
}

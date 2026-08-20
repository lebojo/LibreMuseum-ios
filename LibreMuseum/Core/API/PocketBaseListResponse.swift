import Foundation

nonisolated struct PocketBaseListResponse<Item: Decodable & Sendable>: Decodable, Sendable {
    let page: Int
    let perPage: Int
    let totalItems: Int
    let totalPages: Int
    let items: [Item]

    var hasMorePages: Bool {
        totalPages >= 0 ? page < totalPages : items.count >= perPage
    }
}

import Foundation

nonisolated struct PocketBaseQuery: Sendable {
    static let maxPerPage = 500
    var page: Int?
    var perPage: Int?
    var filter: String?
    var sort: String?
    var expand: String?
    var fields: String?
    var skipTotal = false
    static let singleton = PocketBaseQuery(perPage: 1)

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let page { items.append(URLQueryItem(name: "page", value: String(page))) }
        if let perPage {
            let bounded = min(perPage, Self.maxPerPage)
            items.append(URLQueryItem(name: "perPage", value: String(bounded)))
        }
        if let filter, !filter.isEmpty { items.append(URLQueryItem(name: "filter", value: filter)) }
        if let sort, !sort.isEmpty { items.append(URLQueryItem(name: "sort", value: sort)) }
        if let expand, !expand.isEmpty { items.append(URLQueryItem(name: "expand", value: expand)) }
        if let fields, !fields.isEmpty { items.append(URLQueryItem(name: "fields", value: fields)) }
        if skipTotal { items.append(URLQueryItem(name: "skipTotal", value: "1")) }
        return items
    }

    static func quotedFilterValue(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        return "'\(escaped)'"
    }
}

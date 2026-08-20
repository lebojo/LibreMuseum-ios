import Foundation

nonisolated enum APIConfiguration {
    static let baseURL = URL(string: "http://127.0.0.1:8090")!

    static func mediaPath(collection: String, recordID: String, filename: String) -> String? {
        guard !filename.isEmpty, !recordID.isEmpty, !collection.isEmpty else { return nil }
        return "/api/files/\(collection)/\(recordID)/\(filename)"
    }

    static func mediaPaths(collection: String, recordID: String, filenames: [String]) -> [String] {
        filenames.compactMap {
            mediaPath(collection: collection, recordID: recordID, filename: $0)
        }
    }

    static func mediaURL(path: String, thumb: ThumbSize? = nil) -> URL? {
        guard !path.isEmpty,
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        else { return nil }

        components.path = path
        if let thumb, !path.lowercased().hasSuffix(".svg") {
            components.queryItems = [URLQueryItem(name: "thumb", value: thumb.rawValue)]
        }
        return components.url
    }
}

nonisolated enum ThumbSize: String, Sendable {
    case fit120 = "120x120f"
    case fit512 = "512x512f"
    case square200 = "200x200"
    case card400x300 = "400x300"
    case width400 = "400x0"
    case width600 = "600x0"
    case width800 = "800x0"
    case width1200 = "1200x0"
    case width1600 = "1600x0"
}

nonisolated enum PocketBaseCollection: String, Sendable, CaseIterable {
    case language
    case museum
    case floor
    case room
    case exhibition
    case artwork
    case page
    case exhibitionTranslation = "exhibition_translation"
    case artworkTranslation = "artwork_translation"
    case pageTranslation = "page_translation"
}

import Foundation
import SwiftData

@Model
final class MediaAssetEntity {
    @Attribute(.unique) var cacheKey: String
    var path: String
    @Attribute(.externalStorage) var data: Data
    var byteCount: Int
    var downloadedAt: Date

    init(cacheKey: String, path: String, data: Data, downloadedAt: Date = .now) {
        self.cacheKey = cacheKey
        self.path = path
        self.data = data
        self.byteCount = data.count
        self.downloadedAt = downloadedAt
    }

    static func cacheKey(path: String, thumb: ThumbSize?) -> String {
        guard let thumb else { return path }
        return "\(path)?thumb=\(thumb.rawValue)"
    }
}

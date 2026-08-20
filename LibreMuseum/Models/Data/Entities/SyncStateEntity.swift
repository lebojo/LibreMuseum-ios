import Foundation
import SwiftData

@Model
final class SyncStateEntity {
    static let singletonID = "local"
    @Attribute(.unique) var id: String
    var contentVersion: String
    var lastCheckedAt: Date?
    var selectedLanguageCode: String

    init(
        id: String = SyncStateEntity.singletonID,
        contentVersion: String = "",
        lastCheckedAt: Date? = nil,
        selectedLanguageCode: String = ""
    ) {
        self.id = id
        self.contentVersion = contentVersion
        self.lastCheckedAt = lastCheckedAt
        self.selectedLanguageCode = selectedLanguageCode
    }
}

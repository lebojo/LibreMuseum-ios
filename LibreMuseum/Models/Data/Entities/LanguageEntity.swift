import Foundation
import SwiftData

@Model
final class LanguageEntity {
    @Attribute(.unique) var id: String
    var code: String
    var label: String
    var sort: Int
    var isActive: Bool
    var fetchedVersion: String

    init(
        id: String,
        code: String = "",
        label: String = "",
        sort: Int = 0,
        isActive: Bool = true,
        fetchedVersion: String = ""
    ) {
        self.id = id
        self.code = code
        self.label = label
        self.sort = sort
        self.isActive = isActive
        self.fetchedVersion = fetchedVersion
    }
}

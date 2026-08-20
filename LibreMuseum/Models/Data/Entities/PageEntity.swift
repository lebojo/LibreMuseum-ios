import Foundation
import SwiftData

@Model
final class PageEntity {
    @Attribute(.unique) var id: String
    var slug: String
    var icon: String
    var sort: Int
    var fetchedVersion: String
    @Relationship(deleteRule: .cascade, inverse: \PageTranslationEntity.page)
    var translations: [PageTranslationEntity] = []

    init(
        id: String,
        slug: String = "",
        icon: String = "",
        sort: Int = 0,
        fetchedVersion: String = ""
    ) {
        self.id = id
        self.slug = slug
        self.icon = icon
        self.sort = sort
        self.fetchedVersion = fetchedVersion
    }
}

@Model
final class PageTranslationEntity {
    @Attribute(.unique) var id: String
    var page: PageEntity?
    var languageCode: String
    var title: String
    var body: String
    var fetchedVersion: String

    init(
        id: String,
        languageCode: String = "",
        title: String = "",
        body: String = "",
        fetchedVersion: String = ""
    ) {
        self.id = id
        self.languageCode = languageCode
        self.title = title
        self.body = body
        self.fetchedVersion = fetchedVersion
    }
}

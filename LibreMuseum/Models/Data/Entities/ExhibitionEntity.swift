import Foundation
import SwiftData

@Model
final class ExhibitionEntity {
    @Attribute(.unique) var id: String
    var slug: String
    var coverPath: String
    var colorHex: String?
    var isPermanent: Bool
    var startDate: Date?
    var endDate: Date?
    var roomIDs: [String]
    var sort: Int
    var fetchedVersion: String
    @Relationship(deleteRule: .cascade, inverse: \ExhibitionTranslationEntity.exhibition)
    var translations: [ExhibitionTranslationEntity] = []

    init(
        id: String,
        slug: String = "",
        coverPath: String = "",
        colorHex: String? = "",
        isPermanent: Bool = false,
        startDate: Date? = nil,
        endDate: Date? = nil,
        roomIDs: [String] = [],
        sort: Int = 0,
        fetchedVersion: String = ""
    ) {
        self.id = id
        self.slug = slug
        self.coverPath = coverPath
        self.colorHex = colorHex
        self.isPermanent = isPermanent
        self.startDate = startDate
        self.endDate = endDate
        self.roomIDs = roomIDs
        self.sort = sort
        self.fetchedVersion = fetchedVersion
    }
}

@Model
final class ExhibitionTranslationEntity {
    @Attribute(.unique) var id: String
    var exhibition: ExhibitionEntity?
    var languageCode: String
    var title: String
    var subtitle: String
    var summary: String
    var audioPath: String
    var fetchedVersion: String

    init(
        id: String,
        languageCode: String = "",
        title: String = "",
        subtitle: String = "",
        summary: String = "",
        audioPath: String = "",
        fetchedVersion: String = ""
    ) {
        self.id = id
        self.languageCode = languageCode
        self.title = title
        self.subtitle = subtitle
        self.summary = summary
        self.audioPath = audioPath
        self.fetchedVersion = fetchedVersion
    }
}

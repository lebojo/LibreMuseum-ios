import Foundation
import SwiftData

@Model
final class ArtworkEntity {
    @Attribute(.unique) var id: String
    var exhibitionID: String
    var roomID: String
    var posX: Double
    var posY: Double
    var code: String
    var artist: String
    var year: String
    var technique: String
    var inventoryNumber: String
    var imagePaths: [String]
    var sort: Int
    var fetchedVersion: String
    var hasFullText: Bool
    @Relationship(deleteRule: .cascade, inverse: \ArtworkTranslationEntity.artwork)
    var translations: [ArtworkTranslationEntity] = []

    var isPlaced: Bool { !roomID.isEmpty }

    init(
        id: String,
        exhibitionID: String = "",
        roomID: String = "",
        posX: Double = 0,
        posY: Double = 0,
        code: String = "",
        artist: String = "",
        year: String = "",
        technique: String = "",
        inventoryNumber: String = "",
        imagePaths: [String] = [],
        sort: Int = 0,
        fetchedVersion: String = "",
        hasFullText: Bool = false
    ) {
        self.id = id
        self.exhibitionID = exhibitionID
        self.roomID = roomID
        self.posX = posX
        self.posY = posY
        self.code = code
        self.artist = artist
        self.year = year
        self.technique = technique
        self.inventoryNumber = inventoryNumber
        self.imagePaths = imagePaths
        self.sort = sort
        self.fetchedVersion = fetchedVersion
        self.hasFullText = hasFullText
    }
}

@Model
final class ArtworkTranslationEntity {
    @Attribute(.unique) var id: String
    var artwork: ArtworkEntity?
    var languageCode: String
    var title: String
    var text: String
    var audioPath: String
    var audioDuration: Int
    var fetchedVersion: String

    init(
        id: String,
        languageCode: String = "",
        title: String = "",
        text: String = "",
        audioPath: String = "",
        audioDuration: Int = 0,
        fetchedVersion: String = ""
    ) {
        self.id = id
        self.languageCode = languageCode
        self.title = title
        self.text = text
        self.audioPath = audioPath
        self.audioDuration = audioDuration
        self.fetchedVersion = fetchedVersion
    }
}

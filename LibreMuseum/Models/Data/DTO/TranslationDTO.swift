import Foundation

nonisolated struct ExhibitionTranslationDTO: Decodable, Sendable {
    let id: String
    let collectionName: String
    let exhibitionID: String
    let languageID: String
    let title: String
    let subtitle: String
    let description: String
    let audio: String

    var audioPath: String? {
        APIConfiguration.mediaPath(collection: collectionName, recordID: id, filename: audio)
    }

    private enum CodingKeys: String, CodingKey {
        case id, collectionName, title, subtitle, description, audio
        case exhibitionID = "exhibition"
        case languageID = "language"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.stringOrEmpty(.id)
        collectionName = container.stringOrEmpty(.collectionName)
        exhibitionID = container.stringOrEmpty(.exhibitionID)
        languageID = container.stringOrEmpty(.languageID)
        title = container.stringOrEmpty(.title)
        subtitle = container.stringOrEmpty(.subtitle)
        description = container.stringOrEmpty(.description)
        audio = container.stringOrEmpty(.audio)
    }
}

nonisolated struct ArtworkTranslationDTO: Decodable, Sendable {
    let id: String
    let collectionName: String
    let artworkID: String
    let languageID: String
    let title: String
    let text: String
    let audio: String
    let audioDuration: Int

    var audioPath: String? {
        APIConfiguration.mediaPath(collection: collectionName, recordID: id, filename: audio)
    }

    private enum CodingKeys: String, CodingKey {
        case id, collectionName, title, text, audio
        case artworkID = "artwork"
        case languageID = "language"
        case audioDuration = "audio_duration"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.stringOrEmpty(.id)
        collectionName = container.stringOrEmpty(.collectionName)
        artworkID = container.stringOrEmpty(.artworkID)
        languageID = container.stringOrEmpty(.languageID)
        title = container.stringOrEmpty(.title)
        text = container.stringOrEmpty(.text)
        audio = container.stringOrEmpty(.audio)
        audioDuration = container.intOrZero(.audioDuration)
    }
}

nonisolated struct PageTranslationDTO: Decodable, Sendable {
    let id: String
    let pageID: String
    let languageID: String
    let title: String
    let body: String

    private enum CodingKeys: String, CodingKey {
        case id, title, body
        case pageID = "page"
        case languageID = "language"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.stringOrEmpty(.id)
        pageID = container.stringOrEmpty(.pageID)
        languageID = container.stringOrEmpty(.languageID)
        title = container.stringOrEmpty(.title)
        body = container.stringOrEmpty(.body)
    }
}

import Foundation

nonisolated struct ArtworkDTO: Decodable, Sendable {
    let id: String
    let collectionName: String
    let exhibitionID: String
    let roomID: String
    let posX: Double
    let posY: Double
    let code: String
    let artist: String
    let year: String
    let technique: String
    let inventoryNumber: String
    let images: [String]
    let sort: Int

    var imagePaths: [String] {
        APIConfiguration.mediaPaths(collection: collectionName, recordID: id, filenames: images)
    }

    var primaryImagePath: String? { imagePaths.first }

    private enum CodingKeys: String, CodingKey {
        case id, collectionName, code, artist, year, technique, images, sort
        case exhibitionID = "exhibition"
        case roomID = "room"
        case posX = "pos_x"
        case posY = "pos_y"
        case inventoryNumber = "inventory_number"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.stringOrEmpty(.id)
        collectionName = container.stringOrEmpty(.collectionName)
        exhibitionID = container.stringOrEmpty(.exhibitionID)
        roomID = container.stringOrEmpty(.roomID)
        posX = container.doubleOrZero(.posX)
        posY = container.doubleOrZero(.posY)
        code = container.stringOrEmpty(.code)
        artist = container.stringOrEmpty(.artist)
        year = container.stringOrEmpty(.year)
        technique = container.stringOrEmpty(.technique)
        inventoryNumber = container.stringOrEmpty(.inventoryNumber)
        images = container.stringsOrEmpty(.images)
        sort = container.intOrZero(.sort)
    }
}

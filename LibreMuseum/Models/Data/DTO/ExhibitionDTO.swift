import Foundation

nonisolated struct ExhibitionDTO: Decodable, Sendable {
    let id: String
    let collectionName: String
    let slug: String
    let cover: String
    let isPermanent: Bool
    let startDate: Date?
    let endDate: Date?
    let roomIDs: [String]
    let sort: Int

    var coverPath: String? {
        APIConfiguration.mediaPath(collection: collectionName, recordID: id, filename: cover)
    }

    private enum CodingKeys: String, CodingKey {
        case id, collectionName, slug, cover, sort
        case isPermanent = "is_permanent"
        case startDate = "start_date"
        case endDate = "end_date"
        case roomIDs = "rooms"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.stringOrEmpty(.id)
        collectionName = container.stringOrEmpty(.collectionName)
        slug = container.stringOrEmpty(.slug)
        cover = container.stringOrEmpty(.cover)
        isPermanent = container.boolOrFalse(.isPermanent)
        startDate = container.dateOrNil(.startDate)
        endDate = container.dateOrNil(.endDate)
        roomIDs = container.stringsOrEmpty(.roomIDs)
        sort = container.intOrZero(.sort)
    }
}

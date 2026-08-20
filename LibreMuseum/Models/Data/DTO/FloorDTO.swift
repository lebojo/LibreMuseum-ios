import Foundation

nonisolated struct FloorDTO: Decodable, Sendable {
    let id: String
    let collectionName: String
    let name: String
    let level: Int
    let map: String
    let sort: Int

    var mapPath: String? {
        APIConfiguration.mediaPath(collection: collectionName, recordID: id, filename: map)
    }

    private enum CodingKeys: String, CodingKey {
        case id, collectionName, name, level, map, sort
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.stringOrEmpty(.id)
        collectionName = container.stringOrEmpty(.collectionName)
        name = container.stringOrEmpty(.name)
        level = container.intOrZero(.level)
        map = container.stringOrEmpty(.map)
        sort = container.intOrZero(.sort)
    }
}

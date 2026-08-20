import Foundation

nonisolated struct RoomDTO: Decodable, Sendable {
    let id: String
    let floorID: String
    let name: String
    let code: String
    let sort: Int

    private enum CodingKeys: String, CodingKey {
        case id, name, code, sort
        case floorID = "floor"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.stringOrEmpty(.id)
        floorID = container.stringOrEmpty(.floorID)
        name = container.stringOrEmpty(.name)
        code = container.stringOrEmpty(.code)
        sort = container.intOrZero(.sort)
    }
}

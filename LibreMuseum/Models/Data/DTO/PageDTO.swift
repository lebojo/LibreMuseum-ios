import Foundation

nonisolated struct PageDTO: Decodable, Sendable {
    let id: String
    let slug: String
    let icon: String
    let sort: Int

    private enum CodingKeys: String, CodingKey {
        case id, slug, icon, sort
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.stringOrEmpty(.id)
        slug = container.stringOrEmpty(.slug)
        icon = container.stringOrEmpty(.icon)
        sort = container.intOrZero(.sort)
    }
}

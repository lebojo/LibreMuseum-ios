import Foundation

nonisolated struct LanguageDTO: Decodable, Sendable {
    let id: String
    let code: String
    let label: String
    let sort: Int
    let active: Bool

    private enum CodingKeys: String, CodingKey {
        case id, code, label, sort, active
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.stringOrEmpty(.id)
        code = container.stringOrEmpty(.code)
        label = container.stringOrEmpty(.label)
        sort = container.intOrZero(.sort)
        active = container.boolOrFalse(.active)
    }
}

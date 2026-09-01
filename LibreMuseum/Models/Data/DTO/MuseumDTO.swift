import Foundation

nonisolated struct MuseumDTO: Decodable, Sendable {
    let id: String
    let collectionName: String
    let name: String
    let subtitle: String
    let logo: String
    let cover: String
    let primaryColor: String
    let accentColor: String
    let defaultLanguageID: String
    let ticketValidityHours: Int
    let website: String
    let email: String
    let phone: String
    let address: String
    let latitude: Double
    let longitude: Double

    var logoPath: String? {
        APIConfiguration.mediaPath(collection: collectionName, recordID: id, filename: logo)
    }

    var coverPath: String? {
        APIConfiguration.mediaPath(collection: collectionName, recordID: id, filename: cover)
    }

    private enum CodingKeys: String, CodingKey {
        case id, collectionName, name, subtitle, logo, cover, website, email, phone, address
        case primaryColor = "primary_color"
        case accentColor = "accent_color"
        case defaultLanguageID = "default_lang"
        case ticketValidityHours = "ticket_validity_hours"
        case location
    }

    private enum LocationKeys: String, CodingKey {
        case lat, lon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.stringOrEmpty(.id)
        collectionName = container.stringOrEmpty(.collectionName)
        name = container.stringOrEmpty(.name)
        subtitle = container.stringOrEmpty(.subtitle)
        logo = container.stringOrEmpty(.logo)
        cover = container.stringOrEmpty(.cover)
        primaryColor = container.stringOrEmpty(.primaryColor)
        accentColor = container.stringOrEmpty(.accentColor)
        defaultLanguageID = container.stringOrEmpty(.defaultLanguageID)
        ticketValidityHours = container.intOrZero(.ticketValidityHours)
        website = container.stringOrEmpty(.website)
        email = container.stringOrEmpty(.email)
        phone = container.stringOrEmpty(.phone)
        address = container.stringOrEmpty(.address)

        let location = try? container.nestedContainer(keyedBy: LocationKeys.self, forKey: .location)
        latitude = location?.doubleOrZero(.lat) ?? 0
        longitude = location?.doubleOrZero(.lon) ?? 0
    }
}

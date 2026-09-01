import Foundation
import SwiftData

@Model
final class MuseumEntity {
    @Attribute(.unique) var id: String
    var name: String
    var subtitle: String
    var logoPath: String
    var coverPath: String
    var primaryColorHex: String
    var accentColorHex: String
    var defaultLanguageID: String
    var ticketValidityHours: Int = 0
    var website: String
    var email: String
    var phone: String
    var address: String
    var latitude: Double
    var longitude: Double
    var fetchedVersion: String

    init(
        id: String,
        name: String = "",
        subtitle: String = "",
        logoPath: String = "",
        coverPath: String = "",
        primaryColorHex: String = "",
        accentColorHex: String = "",
        defaultLanguageID: String = "",
        ticketValidityHours: Int = 0,
        website: String = "",
        email: String = "",
        phone: String = "",
        address: String = "",
        latitude: Double = 0,
        longitude: Double = 0,
        fetchedVersion: String = ""
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.logoPath = logoPath
        self.coverPath = coverPath
        self.primaryColorHex = primaryColorHex
        self.accentColorHex = accentColorHex
        self.defaultLanguageID = defaultLanguageID
        self.ticketValidityHours = ticketValidityHours
        self.website = website
        self.email = email
        self.phone = phone
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.fetchedVersion = fetchedVersion
    }
}

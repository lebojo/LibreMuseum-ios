import Foundation

nonisolated struct MuseumContactUI: Sendable, Equatable {
    let website: String
    let email: String
    let phone: String
    let address: String
    let latitude: Double
    let longitude: Double

    var websiteURL: URL? { URL(string: website) }

    var mapsURL: URL? {
        guard latitude != 0 || longitude != 0 else { return nil }
        return URL(string: "http://maps.apple.com/?ll=\(latitude),\(longitude)")
    }

    var isEmpty: Bool {
        website.isEmpty && email.isEmpty && phone.isEmpty && address.isEmpty && mapsURL == nil
    }
}

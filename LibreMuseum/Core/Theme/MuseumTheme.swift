import SwiftUI

@Observable
@MainActor
final class MuseumTheme {
    private(set) var primaryHex: String = ""
    private(set) var accentHex: String = ""

    var primary: Color { Color(museumHex: primaryHex) ?? .museumPrimaryFallback }

    var accent: Color { Color(museumHex: accentHex) ?? .museumAccentFallback }

    func apply(primaryHex: String, accentHex: String) {
        self.primaryHex = primaryHex
        self.accentHex = accentHex
    }

    func reset() {
        primaryHex = ""
        accentHex = ""
    }
}

extension Color {
    static let museumPrimaryFallback = Color.primary
    static let museumAccentFallback = Color.accentColor
}

import SwiftUI

@Observable
@MainActor
final class MuseumTheme {
    private(set) var primaryHex: String = ""
    private(set) var accentHex: String = ""

    var primary: Color { Color(museumHex: primaryHex) ?? .museumPrimaryFallback }

    var accent: Color { Color(museumHex: accentHex) ?? .museumAccentFallback }

    func legiblePrimary(on scheme: ColorScheme) -> Color {
        guard let luminance = MuseumHex.relativeLuminance(primaryHex) else {
            return .museumPrimaryFallback
        }
        let staysReadable = scheme == .dark ? luminance > 0.2 : luminance < 0.7
        return staysReadable ? primary : .museumPrimaryFallback
    }

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

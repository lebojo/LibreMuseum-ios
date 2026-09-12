import SwiftUI

nonisolated enum MuseumHex {
    static func components(_ hex: String) -> (red: Double, green: Double, blue: Double)? {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let rgb = UInt32(value, radix: 16) else { return nil }

        return (
            Double((rgb & 0xFF0000) >> 16) / 255,
            Double((rgb & 0x00FF00) >> 8) / 255,
            Double(rgb & 0x0000FF) / 255
        )
    }

    static func relativeLuminance(_ hex: String) -> Double? {
        guard let components = components(hex) else { return nil }
        return 0.2126 * linear(components.red)
            + 0.7152 * linear(components.green)
            + 0.0722 * linear(components.blue)
    }

    private static func linear(_ channel: Double) -> Double {
        channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }
}

extension Color {
    init?(museumHex hex: String) {
        guard let components = MuseumHex.components(hex) else { return nil }
        self.init(red: components.red, green: components.green, blue: components.blue)
    }

    static func museumLegibleForeground(onHex hex: String) -> Color? {
        guard let luminance = MuseumHex.relativeLuminance(hex) else { return nil }
        let blackContrast = (luminance + 0.05) / 0.05
        let whiteContrast = 1.05 / (luminance + 0.05)
        return blackContrast >= whiteContrast ? .black : .white
    }
}

import SwiftUI

struct MapPinView: View {
    static let diameter: CGFloat = 32

    @Environment(MuseumTheme.self) private var theme

    let label: String
    let colorHex: String

    private var effectiveHex: String {
        Color(museumHex: colorHex) == nil ? theme.accentHex : colorHex
    }

    private var fillColor: Color {
        Color(museumHex: effectiveHex) ?? .museumAccentFallback
    }

    private var labelColor: Color {
        Color.museumLegibleForeground(onHex: effectiveHex) ?? .white
    }

    var body: some View {
        Text(label)
            .font(.museumCaption.bold().monospacedDigit())
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(2)
            .foregroundStyle(labelColor)
            .frame(width: Self.diameter, height: Self.diameter)
            .background(fillColor, in: Circle())
            .overlay(Circle().stroke(labelColor, lineWidth: 2))
            .shadow(radius: 2, y: 1)
    }
}

import SwiftUI

struct MapPinView: View {
    static let diameter: CGFloat = 32

    @Environment(MuseumTheme.self) private var theme

    let label: String
    let colorHex: String
    var isLocked = false

    private var effectiveHex: String {
        Color(museumHex: colorHex) == nil ? theme.accentHex : colorHex
    }

    private var fillColor: Color {
        Color(museumHex: effectiveHex) ?? .museumAccentFallback
    }

    private var fillStyle: AnyShapeStyle {
        isLocked ? AnyShapeStyle(.secondary) : AnyShapeStyle(fillColor)
    }

    private var labelColor: Color {
        if isLocked { return .white }
        return Color.museumLegibleForeground(onHex: effectiveHex) ?? .white
    }

    var body: some View {
        Text(label)
            .font(.museumCaption.bold().monospacedDigit())
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(2)
            .foregroundStyle(labelColor)
            .frame(width: Self.diameter, height: Self.diameter)
            .background(fillStyle, in: Circle())
            .overlay(Circle().stroke(labelColor, lineWidth: 2))
            .overlay(alignment: .bottomTrailing) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(2)
                        .background(theme.accent, in: Circle())
                        .offset(x: 2, y: 2)
                }
            }
            .shadow(radius: 2, y: 1)
    }
}

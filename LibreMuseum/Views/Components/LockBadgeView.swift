import SwiftUI

struct LockBadgeView: View {
    @Environment(MuseumTheme.self) private var theme

    var font: Font = .museumCaption

    var body: some View {
        Image(systemName: "lock.fill")
            .font(font)
            .foregroundStyle(theme.accent)
            .accessibilityLabel("Locked, a ticket is required")
    }
}

import SwiftUI

struct TicketPromptHeaderView: View {
    @Environment(MuseumTheme.self) private var theme

    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(theme.accent)

            Text(title)
                .font(.museumHeadline)
                .multilineTextAlignment(.center)

            Text("Buy your ticket at the museum and scan the QR code here to unlock.")
                .font(.museumBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }
}

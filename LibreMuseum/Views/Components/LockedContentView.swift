import SwiftUI

struct LockedContentView: View {
    @Environment(MuseumTheme.self) private var theme

    let exhibition: LockedExhibitionUI
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            TicketPromptHeaderView(title: exhibition.title)

            Button("Scan the QR code", systemImage: "qrcode.viewfinder", action: onUnlock)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(theme.accent)
        }
        .padding()
    }
}

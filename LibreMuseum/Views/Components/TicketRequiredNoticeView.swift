import SwiftUI

struct TicketRequiredNoticeView: View {
    @Environment(MuseumTheme.self) private var theme

    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Ticket required", systemImage: "lock.fill")
                .font(.museumHeadline)
                .foregroundStyle(theme.accent)

            Text("Buy your ticket at the museum and scan the QR code here to unlock the artworks.")
                .font(.museumCaption)
                .foregroundStyle(.secondary)
                // A List row hands its content an unbounded proposed width and
                // then truncates: the text has to ask for its own height.
                .fixedSize(horizontal: false, vertical: true)

            Button("Scan the QR code", systemImage: "qrcode.viewfinder", action: onUnlock)
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

import SwiftUI

struct TicketNoticeView: View {
    @Environment(MuseumTheme.self) private var theme

    let exhibition: ExhibitionDetailUI
    let onUnlock: () -> Void

    // A stored scan outlives the requirement it was made for: an exhibition the
    // museum has since freed, by dropping the requirement or by clearing its code,
    // must not still advertise a deadline.
    private var isStillGated: Bool {
        exhibition.requiresTicket && !exhibition.unlockCode.isEmpty
    }

    var body: some View {
        if exhibition.isLocked {
            lockedNotice
        } else if isStillGated, let deadline = exhibition.unlockedUntil {
            unlockedNotice(until: deadline)
        }
    }

    private var lockedNotice: some View {
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

    private func unlockedNotice(until deadline: Date) -> some View {
        Label {
            Text("Unlocked until \(deadline.formatted(date: .omitted, time: .shortened))")
        } icon: {
            Image(systemName: "lock.open.fill")
        }
        .font(.museumCaption)
        .foregroundStyle(.secondary)
    }
}

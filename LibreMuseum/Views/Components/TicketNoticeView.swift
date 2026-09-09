import SwiftUI

struct TicketNoticeView: View {
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
            TicketRequiredNoticeView(onUnlock: onUnlock)
        } else if isStillGated, let deadline = exhibition.unlockedUntil {
            TicketUnlockedNoticeView(deadline: deadline)
        }
    }
}

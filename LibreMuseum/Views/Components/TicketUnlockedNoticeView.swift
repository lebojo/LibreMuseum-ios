import SwiftUI

struct TicketUnlockedNoticeView: View {
    let deadline: Date

    var body: some View {
        Label {
            Text("Unlocked until \(deadline.formatted(date: .omitted, time: .shortened))")
        } icon: {
            Image(systemName: "lock.open.fill")
        }
        .font(.museumCaption)
        .foregroundStyle(.secondary)
    }
}

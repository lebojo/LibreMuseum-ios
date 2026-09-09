import SwiftUI

struct TicketUnlockedNoticeView: View {
    let deadline: Date

    // A ticket valid for a day or three reads as an hour alone: "until 14:30"
    // is either today or tomorrow, and the visitor cannot tell which.
    private var formattedDeadline: String {
        Calendar.current.isDateInToday(deadline)
            ? deadline.formatted(date: .omitted, time: .shortened)
            : deadline.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        Label {
            Text("Unlocked until \(formattedDeadline)")
        } icon: {
            Image(systemName: "lock.open.fill")
        }
        .font(.museumCaption)
        .foregroundStyle(.secondary)
    }
}

import SwiftUI

extension View {
    func ticketPrompt(for exhibition: Binding<LockedExhibitionUI?>) -> some View {
        sheet(item: exhibition) { TicketPromptView(exhibition: $0) }
    }
}

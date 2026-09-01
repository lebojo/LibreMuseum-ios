import SwiftUI

// The way in when the camera is refused, broken, or simply not the visitor's
// habit: the same code, typed. Collapsed by default so the QR stays the offer.
struct TicketCodeEntryView: View {
    @State private var isExpanded = false
    @State private var typed = ""

    let onSubmit: (String) -> Void

    var body: some View {
        DisclosureGroup("Enter the code by hand", isExpanded: $isExpanded) {
            HStack {
                TextField("Code", text: $typed)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(send)

                Button("Unlock", action: send)
                    .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.top, 8)
        }
        .font(.museumCaption)
    }

    private func send() {
        let code = typed
        guard !code.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        typed = ""
        onSubmit(code)
    }
}

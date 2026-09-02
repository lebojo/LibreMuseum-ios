import SwiftData
import SwiftUI

struct TicketPromptView: View {
    private enum Outcome: Equatable {
        case waiting
        case wrongCode
        case cameraUnavailable(String)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(MuseumTheme.self) private var theme
    @Environment(TicketStore.self) private var tickets
    @Query private var museums: [MuseumEntity]
    @State private var isScanning = false
    @State private var scannedPayload: String?
    @State private var outcome: Outcome = .waiting

    let exhibition: LockedExhibitionUI

    private var validityHours: Int { museums.first?.ticketValidityHours ?? 0 }

    private var failureMessage: String? {
        switch outcome {
        case .waiting: nil
        case .wrongCode: String(localized: "This code does not unlock this exhibition.")
        case .cameraUnavailable(let message): message
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    TicketPromptHeaderView(title: exhibition.title)

                    Button("Scan the QR code", systemImage: "qrcode.viewfinder") {
                        isScanning = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(theme.accent)

                    TicketCodeEntryView { submit($0) }

                    if let message = failureMessage {
                        Text(message)
                            .font(.museumCaption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("Unlock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $isScanning, onDismiss: submitScannedPayload) {
                TicketScannerView(
                    simulatedPayload: exhibition.unlockCode,
                    onScan: { payload in
                        scannedPayload = payload
                        isScanning = false
                    },
                    onUnavailable: { message in
                        isScanning = false
                        outcome = .cameraUnavailable(message)
                    }
                )
            }
        }
    }

    // Dismissing this sheet in the same update as the scanner it presents
    // swallows the dismissal: the unlock is persisted, and the prompt stays on
    // screen as if the scan had failed. The scan is replayed once it is gone.
    private func submitScannedPayload() {
        guard let payload = scannedPayload else { return }
        scannedPayload = nil
        submit(payload)
    }

    private func submit(_ payload: String) {
        guard TicketCode.matches(scannedPayload: payload, unlockCode: exhibition.unlockCode) else {
            outcome = .wrongCode
            return
        }
        tickets.unlock(exhibitionID: exhibition.id, forHours: validityHours)
        dismiss()
    }
}

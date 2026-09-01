import AVFoundation
import CodeScanner
import SwiftUI

struct TicketScannerView: View {
    @Environment(\.dismiss) private var dismiss

    // CodeScanner hands this string back instead of a scan when it runs in the
    // simulator, where no camera exists. It is the only way to walk through the
    // unlock on a simulator build.
    let simulatedPayload: String
    let onScan: (String) -> Void
    let onUnavailable: (String) -> Void

    var body: some View {
        NavigationStack {
            CodeScannerView(
                codeTypes: [.qr],
                scanMode: .once,
                showViewfinder: true,
                simulatedData: simulatedPayload,
                completion: handle
            )
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Scan the QR code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func handle(_ result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let scan):
            onScan(scan.string)
        case .failure(let error):
            onUnavailable(Self.message(for: error))
        }
    }

    private static func message(for error: ScanError) -> String {
        switch error {
        case .permissionDenied:
            String(localized: "The camera is not allowed. Enable it in Settings, or type the code by hand.")
        case .badInput, .badOutput, .initError:
            String(localized: "The camera is unavailable. Type the code by hand instead.")
        @unknown default:
            String(localized: "The camera is unavailable. Type the code by hand instead.")
        }
    }
}

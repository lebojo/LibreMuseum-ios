import SwiftUI

struct StorageSectionView: View {
    @Environment(ContentSyncService.self) private var sync
    @State private var isConfirmingPurge = false

    private var isPrefetching: Bool {
        if case .prefetching = sync.state { return true }
        return false
    }

    private var prefetchProgress: Double {
        if case .prefetching(let progress) = sync.state { return progress }
        return 0
    }

    var body: some View {
        Section {
            LabeledContent("Space used") {
                Text(sync.storageBytes.formatted(.byteCount(style: .file)))
                    .foregroundStyle(.secondary)
            }

            if isPrefetching {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: prefetchProgress)
                    Text("\(Int(prefetchProgress * 100))%")
                        .font(.museumCaption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button("Download everything") {
                    Task { await sync.prefetchAll() }
                }
            }

            Button("Delete everything", role: .destructive) {
                isConfirmingPurge = true
            }
            .disabled(isPrefetching)
        } header: {
            Text("Local data")
        } footer: {
            Text("Download every image and audio guide before your visit: reception is poor inside the galleries.")
        }
        .confirmationDialog(
            "Delete all downloaded content?",
            isPresented: $isConfirmingPurge,
            titleVisibility: .visible
        ) {
            Button("Delete everything", role: .destructive) {
                Task { await sync.purgeAll() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Content will be downloaded again next time you open it. Your language is kept.")
        }
    }
}

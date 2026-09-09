import SwiftUI

struct ContentVersionSectionView: View {
    let version: String
    let lastCheckedAt: Date?

    private var versionLabel: String {
        version.isEmpty ? "—" : version
    }

    private var lastCheckedLabel: String {
        guard let lastCheckedAt else { return String(localized: "Never") }
        return lastCheckedAt.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        Section {
            LabeledContent("Content version") {
                Text(versionLabel)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Last checked") {
                Text(lastCheckedLabel)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Content")
        } footer: {
            Text("The app compares this fingerprint with the server's at every launch and only downloads what changed.")
        }
    }
}

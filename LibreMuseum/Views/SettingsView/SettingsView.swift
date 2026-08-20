import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(ContentSyncService.self) private var sync
    @Environment(\.dismiss) private var dismiss
    @Query(
        filter: #Predicate<LanguageEntity> { $0.isActive },
        sort: [SortDescriptor(\LanguageEntity.sort), SortDescriptor(\LanguageEntity.code)]
    )
    private var languages: [LanguageEntity]
    @Query private var museums: [MuseumEntity]

    private var museumDefaultCode: String {
        guard let museum = museums.first else { return "" }
        return languages.first { $0.id == museum.defaultLanguageID }?.code ?? ""
    }

    private var displayCode: String {
        LanguageResolver.displayCode(
            selected: sync.selectedLanguageCode,
            availableCodes: languages.map(\.code),
            museumDefault: museumDefaultCode
        ) ?? ""
    }

    var body: some View {
        NavigationStack {
            List {
                LanguagePickerView(
                    languages: languages.map(EntityToUI.language),
                    selectedCode: displayCode,
                    onSelect: { code in Task { await sync.selectLanguage(code) } }
                )

                ContentVersionSectionView(
                    version: sync.contentVersion,
                    lastCheckedAt: sync.lastCheckedAt
                )

                StorageSectionView()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }

}

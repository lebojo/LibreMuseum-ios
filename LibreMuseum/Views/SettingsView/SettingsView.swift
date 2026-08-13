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

    private var languageContext: LanguageContext {
        EntityToUI.languageContext(
            museum: museums.first,
            languages: languages,
            selectedCode: sync.selectedLanguageCode
        )
    }

    var body: some View {
        NavigationStack {
            List {
                LanguagePickerView(
                    languages: languages.map(EntityToUI.language),
                    selectedCode: languageContext.displayCode,
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

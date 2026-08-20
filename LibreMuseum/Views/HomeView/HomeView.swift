import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(ContentSyncService.self) private var sync
    @Query private var museums: [MuseumEntity]
    @Query(sort: [SortDescriptor(\ExhibitionEntity.sort), SortDescriptor(\ExhibitionEntity.slug)])
    private var exhibitions: [ExhibitionEntity]
    @Query(
        filter: #Predicate<LanguageEntity> { $0.isActive },
        sort: [SortDescriptor(\LanguageEntity.sort), SortDescriptor(\LanguageEntity.code)]
    )
    private var languages: [LanguageEntity]
    @State private var isShowingSettings = false

    private var museum: MuseumEntity? { museums.first }

    private var displayCode: String {
        LanguageResolver.displayCode(
            selected: sync.selectedLanguageCode,
            availableCodes: languages.map(\.code),
            museumDefault: museumDefaultCode
        ) ?? ""
    }

    private var museumDefaultCode: String {
        guard let museum else { return "" }
        return languages.first { $0.id == museum.defaultLanguageID }?.code ?? ""
    }

    private var exhibitionItems: [ExhibitionUI] {
        exhibitions.map {
            EntityToUI.exhibition($0, languageCode: displayCode, museumDefault: museumDefaultCode)
        }
    }

    private var emptyStateReason: HomeEmptyStateView.Reason {
        if case .failed(let message) = sync.state { return .unreachable(message) }
        if sync.state == .checking || museum == nil { return .loading }
        return .noExhibition
    }

    var body: some View {
        NavigationStack {
            List {
                if let museum {
                    Section {
                        MuseumHeaderView(museum: EntityToUI.museum(museum))
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                    }
                }

                if exhibitionItems.isEmpty {
                    Section {
                        HomeEmptyStateView(reason: emptyStateReason) {
                            Task { await sync.start() }
                        }
                    }
                } else {
                    Section("Exhibitions") {
                        ForEach(exhibitionItems) { item in
                            ExhibitionRowView(exhibition: item)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(museum?.name ?? "")
            .navigationBarTitleDisplayMode(museum == nil ? .large : .inline)
            .toolbar {
                ToolbarItem {
                    Button("Settings", systemImage: "gear") { isShowingSettings = true }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .refreshable { await sync.start() }
            .task { await sync.start() }
        }
    }
}

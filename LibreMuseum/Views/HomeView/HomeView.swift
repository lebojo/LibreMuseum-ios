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
    @State private var isShowingInfo = false
    @State private var isShowingSettings = false

    private var museum: MuseumEntity? { museums.first }

    private var languageContext: LanguageContext {
        EntityToUI.languageContext(
            museum: museum,
            languages: languages,
            selectedCode: sync.selectedLanguageCode
        )
    }

    private var exhibitionItems: [ExhibitionUI] {
        exhibitions.map { EntityToUI.exhibition($0, in: languageContext) }
    }

    private var emptyState: ContentStateView.State {
        if case .failed(let message) = sync.state { return .unreachable(message) }
        if sync.state == .checking || museum == nil { return .loading("Loading the museum") }
        return .empty("No exhibitions", "The museum has not published any exhibition yet.")
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
                        ContentStateView(state: emptyState) {
                            Task { await sync.start() }
                        }
                    }
                } else {
                    Section("Exhibitions") {
                        ForEach(exhibitionItems) { item in
                            NavigationLink(value: item) {
                                ExhibitionRowView(exhibition: item)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(museum?.name ?? "")
            .navigationBarTitleDisplayMode(museum == nil ? .large : .inline)
            .navigationDestination(for: ExhibitionUI.self) {
                ExhibitionDetailView(exhibitionID: $0.id)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Information", systemImage: "info.circle") { isShowingInfo = true }
                }
                ToolbarItem {
                    Button("Settings", systemImage: "gear") { isShowingSettings = true }
                }
            }
            .sheet(isPresented: $isShowingInfo) {
                MuseumInfoView()
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .refreshable { await sync.start() }
            .task { await sync.start() }
        }
    }
}

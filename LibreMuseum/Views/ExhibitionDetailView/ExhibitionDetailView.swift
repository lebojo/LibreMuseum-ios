import SwiftData
import SwiftUI

struct ExhibitionDetailView: View {
    @Environment(ContentSyncService.self) private var sync
    @Query private var museums: [MuseumEntity]
    @Query(
        filter: #Predicate<LanguageEntity> { $0.isActive },
        sort: [SortDescriptor(\LanguageEntity.sort), SortDescriptor(\LanguageEntity.code)]
    )
    private var languages: [LanguageEntity]
    @Query private var exhibitions: [ExhibitionEntity]
    @Query private var artworks: [ArtworkEntity]
    @State private var isLoadingArtworks = false

    let exhibitionID: String

    init(exhibitionID: String) {
        self.exhibitionID = exhibitionID
        _exhibitions = Query(filter: #Predicate<ExhibitionEntity> { $0.id == exhibitionID })
        _artworks = Query(
            filter: #Predicate<ArtworkEntity> { $0.exhibitionID == exhibitionID },
            sort: [SortDescriptor(\ArtworkEntity.sort), SortDescriptor(\ArtworkEntity.code)]
        )
    }

    private var languageContext: LanguageContext {
        EntityToUI.languageContext(
            museum: museums.first,
            languages: languages,
            selectedCode: sync.selectedLanguageCode
        )
    }

    private var detail: ExhibitionDetailUI? {
        guard let entity = exhibitions.first else { return nil }
        return EntityToUI.exhibitionDetail(entity, in: languageContext)
    }

    private var artworkItems: [ArtworkUI] {
        artworks.map { EntityToUI.artwork($0, in: languageContext) }
    }

    private var emptyState: ContentStateView.State {
        if isLoadingArtworks { return .loading("Loading the artworks") }
        if case .failed(let message) = sync.state { return .unreachable(message) }
        return .empty("No artworks", "This exhibition has no artwork yet.")
    }

    var body: some View {
        List {
            if let detail {
                Section {
                    ExhibitionHeaderView(exhibition: detail)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
            }

            if artworkItems.isEmpty {
                Section {
                    ContentStateView(state: emptyState) {
                        Task { await sync.reloadArtworks(exhibitionID: exhibitionID) }
                    }
                }
            } else {
                Section("Artworks") {
                    ForEach(artworkItems) { item in
                        NavigationLink(value: item) {
                            ArtworkRowView(artwork: item)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(detail?.title ?? "")
        .navigationDestination(for: ArtworkUI.self) { ArtworkDetailView(artworkID: $0.id) }
        .refreshable { await sync.reloadArtworks(exhibitionID: exhibitionID) }
        .task {
            isLoadingArtworks = true
            await sync.loadArtworksIfNeeded(exhibitionID: exhibitionID)
            isLoadingArtworks = false
        }
    }
}

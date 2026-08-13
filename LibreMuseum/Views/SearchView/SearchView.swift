import SwiftData
import SwiftUI

struct SearchView: View {
    private struct RankedArtwork {
        let relevance: ArtworkSearch.Relevance
        let position: Int
        let item: ArtworkUI
    }

    @Environment(ContentSyncService.self) private var sync
    @Query private var museums: [MuseumEntity]
    @Query(
        filter: #Predicate<LanguageEntity> { $0.isActive },
        sort: [SortDescriptor(\LanguageEntity.sort), SortDescriptor(\LanguageEntity.code)]
    )
    private var languages: [LanguageEntity]
    @Query(sort: [SortDescriptor(\ExhibitionEntity.sort), SortDescriptor(\ExhibitionEntity.slug)])
    private var exhibitions: [ExhibitionEntity]
    @Query(sort: [SortDescriptor(\ArtworkEntity.sort), SortDescriptor(\ArtworkEntity.code)])
    private var artworks: [ArtworkEntity]
    @State private var query = ""
    @State private var isLoadingIndex = false

    private var languageContext: LanguageContext {
        EntityToUI.languageContext(
            museum: museums.first,
            languages: languages,
            selectedCode: sync.selectedLanguageCode
        )
    }

    private var artworkResults: [ArtworkUI] {
        guard !query.isEmpty else { return [] }
        let context = languageContext

        let ranked = artworks.enumerated().compactMap { position, entity -> RankedArtwork? in
            let item = EntityToUI.artwork(entity, in: context)
            let fields = ArtworkSearch.Fields(
                code: item.code,
                title: item.title,
                artist: item.artist
            )
            guard let relevance = ArtworkSearch.relevance(of: fields, for: query) else {
                return nil
            }
            return RankedArtwork(relevance: relevance, position: position, item: item)
        }

        return ranked
            .sorted { ($0.relevance, $0.position) < ($1.relevance, $1.position) }
            .map(\.item)
    }

    private var exhibitionResults: [ExhibitionUI] {
        guard !query.isEmpty else { return [] }
        let context = languageContext
        return exhibitions
            .map { EntityToUI.exhibition($0, in: context) }
            .filter { ArtworkSearch.matches($0.title, query: query) }
    }

    private var hasResults: Bool {
        !artworkResults.isEmpty || !exhibitionResults.isEmpty
    }

    private var placeholderState: ContentStateView.State {
        if isLoadingIndex { return .loading("Preparing the search") }
        if query.isEmpty {
            return .empty(
                "Search the collection",
                "Type a title, an artist, or the number written on the label."
            )
        }
        if case .failed(let message) = sync.state, artworks.isEmpty {
            return .unreachable(message)
        }
        return .empty("No result", "No artwork or exhibition matches this search.")
    }

    var body: some View {
        NavigationStack {
            List {
                if hasResults {
                    if !artworkResults.isEmpty {
                        Section("Artworks") {
                            ForEach(artworkResults) { artwork in
                                NavigationLink(value: artwork) {
                                    ArtworkRowView(artwork: artwork)
                                }
                            }
                        }
                    }

                    if !exhibitionResults.isEmpty {
                        Section("Exhibitions") {
                            ForEach(exhibitionResults) { exhibition in
                                NavigationLink(value: exhibition) {
                                    ExhibitionRowView(exhibition: exhibition)
                                }
                            }
                        }
                    }
                } else {
                    Section {
                        ContentStateView(state: placeholderState) {
                            Task { await sync.loadEveryArtworkIfNeeded() }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search")
            .navigationDestination(for: ArtworkUI.self) { ArtworkDetailView(artworkID: $0.id) }
            .navigationDestination(for: ExhibitionUI.self) {
                ExhibitionDetailView(exhibitionID: $0.id)
            }
            .searchable(text: $query, prompt: "Title, artist or label number")
            .task {
                isLoadingIndex = true
                await sync.loadEveryArtworkIfNeeded()
                isLoadingIndex = false
            }
        }
    }
}

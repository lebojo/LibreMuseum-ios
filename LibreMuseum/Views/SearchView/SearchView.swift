import SwiftData
import SwiftUI

struct SearchView: View {
    private struct RankedArtwork {
        let relevance: ArtworkSearch.Relevance
        let position: Int
        let item: ArtworkUI
    }

    @Environment(ContentSyncService.self) private var sync
    @Environment(TicketStore.self) private var tickets
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
    @State private var hasFocusedSearch = false
    @FocusState private var isSearchFocused: Bool
    @State private var promptedExhibition: LockedExhibitionUI?

    private var languageContext: LanguageContext {
        EntityToUI.languageContext(
            museum: museums.first,
            languages: languages,
            selectedCode: sync.selectedLanguageCode
        )
    }

    private var ticketAccess: TicketAccess {
        EntityToUI.ticketAccess(exhibitions: exhibitions, in: languageContext, tickets: tickets)
    }

    private var artworkResults: [ArtworkUI] {
        guard !query.isEmpty else { return [] }
        let context = languageContext
        let access = ticketAccess

        let ranked = artworks.enumerated().compactMap { position, entity -> RankedArtwork? in
            let item = EntityToUI.artwork(entity, in: context, access: access)
            // A locked artwork keeps its real title so that unlocking reveals
            // it without a refetch. Matching on it would confirm the very title
            // the teaser withholds: only the number on the label can find it.
            let fields = ArtworkSearch.Fields(
                code: item.code,
                titles: item.isLocked ? [] : item.searchableTitles,
                artist: item.isLocked ? "" : item.artist
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
        let access = ticketAccess
        return exhibitions
            .map { EntityToUI.exhibition($0, in: context, access: access) }
            .filter { ArtworkSearch.matches($0.searchableTitles, query: query) }
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
        let matchedArtworks = artworkResults
        let matchedExhibitions = exhibitionResults

        NavigationStack {
            List {
                if matchedArtworks.isEmpty, matchedExhibitions.isEmpty {
                    Section {
                        ContentStateView(state: placeholderState) {
                            Task { await sync.loadEveryArtworkIfNeeded() }
                        }
                    }
                } else {
                    if !matchedArtworks.isEmpty {
                        Section("Artworks") {
                            ForEach(matchedArtworks) { artwork in
                                ArtworkLinkView(artwork: artwork) {
                                    promptedExhibition = ticketAccess
                                        .lockedExhibition(id: artwork.exhibitionID)
                                }
                            }
                        }
                    }

                    if !matchedExhibitions.isEmpty {
                        Section("Exhibitions") {
                            ForEach(matchedExhibitions) { exhibition in
                                NavigationLink(value: exhibition) {
                                    ExhibitionRowView(exhibition: exhibition)
                                }
                            }
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
            .ticketPrompt(for: $promptedExhibition)
            .searchable(text: $query, prompt: "Title, artist or label number")
            .searchFocused($isSearchFocused)
            .task {
                if !hasFocusedSearch {
                    hasFocusedSearch = true
                    isSearchFocused = true
                }
                isLoadingIndex = true
                await sync.loadEveryArtworkIfNeeded()
                isLoadingIndex = false
            }
        }
    }
}

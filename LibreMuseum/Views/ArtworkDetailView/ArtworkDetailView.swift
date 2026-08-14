import SwiftData
import SwiftUI

struct ArtworkDetailView: View {
    @Environment(ContentSyncService.self) private var sync
    @Environment(MuseumTheme.self) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Query private var museums: [MuseumEntity]
    @Query(
        filter: #Predicate<LanguageEntity> { $0.isActive },
        sort: [SortDescriptor(\LanguageEntity.sort), SortDescriptor(\LanguageEntity.code)]
    )
    private var languages: [LanguageEntity]
    @Query private var rooms: [RoomEntity]
    @Query private var artworks: [ArtworkEntity]
    @State private var isLoadingDetail = false

    let artworkID: String

    init(artworkID: String) {
        self.artworkID = artworkID
        _artworks = Query(filter: #Predicate<ArtworkEntity> { $0.id == artworkID })
    }

    private var languageContext: LanguageContext {
        EntityToUI.languageContext(
            museum: museums.first,
            languages: languages,
            selectedCode: sync.selectedLanguageCode
        )
    }

    private var artwork: ArtworkDetailUI? {
        guard let entity = artworks.first else { return nil }
        return EntityToUI.artworkDetail(entity, rooms: rooms, in: languageContext)
    }

    private var missingState: ContentStateView.State {
        if isLoadingDetail { return .loading("Loading the artwork") }
        if case .failed(let message) = sync.state { return .unreachable(message) }
        return .empty("Artwork unavailable", "This artwork is no longer shown by the museum.")
    }

    var body: some View {
        ScrollView {
            if let artwork {
                VStack(alignment: .leading, spacing: 20) {
                    if !artwork.imagePaths.isEmpty {
                        ArtworkGalleryView(imagePaths: artwork.imagePaths)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(artwork.title)
                            .font(.museumTitle)
                            .foregroundStyle(theme.legiblePrimary(on: colorScheme))
                            .accessibilityAddTraits(.isHeader)

                        if !artwork.artist.isEmpty {
                            Text(artwork.artist)
                                .font(.museumMeta)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    if artwork.hasAudioGuide {
                        AudioGuideView(path: artwork.audioPath, announcedDuration: artwork.audioDuration)
                            .padding(.horizontal)
                    }

                    if !artwork.text.isEmpty {
                        HTMLTextView(html: artwork.text)
                            .padding(.horizontal)
                    }

                    ArtworkFactsView(artwork: artwork)
                }
                .padding(.bottom, 32)
            } else {
                ContentStateView(state: missingState) {
                    Task { await sync.loadArtworkDetailIfNeeded(id: artworkID) }
                }
                .padding(.top, 80)
            }
        }
        .navigationTitle(artwork?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { Color.clear }
        }
        .task {
            isLoadingDetail = true
            await sync.loadArtworkDetailIfNeeded(id: artworkID)
            isLoadingDetail = false
            await sync.loadMapIfNeeded()
        }
    }
}

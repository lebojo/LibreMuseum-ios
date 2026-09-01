import SwiftData
import SwiftUI

struct ArtworkDetailView: View {
    @Environment(ContentSyncService.self) private var sync
    @Environment(TicketStore.self) private var tickets
    @Query private var museums: [MuseumEntity]
    @Query(
        filter: #Predicate<LanguageEntity> { $0.isActive },
        sort: [SortDescriptor(\LanguageEntity.sort), SortDescriptor(\LanguageEntity.code)]
    )
    private var languages: [LanguageEntity]
    @Query private var rooms: [RoomEntity]
    @Query private var artworks: [ArtworkEntity]
    @Query private var exhibitions: [ExhibitionEntity]
    @State private var isLoadingDetail = false
    @State private var promptedExhibition: LockedExhibitionUI?

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

    private var ticketAccess: TicketAccess {
        EntityToUI.ticketAccess(exhibitions: exhibitions, in: languageContext, tickets: tickets)
    }

    private var artwork: ArtworkDetailUI? {
        guard let entity = artworks.first else { return nil }
        return EntityToUI.artworkDetail(
            entity,
            rooms: rooms,
            in: languageContext,
            access: ticketAccess
        )
    }

    // Reachable when a ticket expires while this very screen is open: the
    // artwork has to close behind the visitor, not stay on display.
    private var lockedExhibition: LockedExhibitionUI? {
        guard let artwork, artwork.isLocked else { return nil }
        return ticketAccess.lockedExhibition(id: artwork.exhibitionID)
    }

    private var missingState: ContentStateView.State {
        if isLoadingDetail { return .loading("Loading the artwork") }
        if case .failed(let message) = sync.state { return .unreachable(message) }
        return .empty("Artwork unavailable", "This artwork is no longer shown by the museum.")
    }

    var body: some View {
        ScrollView {
            if let lockedExhibition {
                LockedContentView(exhibition: lockedExhibition) {
                    promptedExhibition = lockedExhibition
                }
                .padding(.top, 40)
            } else if let artwork {
                VStack(alignment: .leading, spacing: 20) {
                    if !artwork.imagePaths.isEmpty {
                        ArtworkGalleryView(imagePaths: artwork.imagePaths)
                    }

                    if !artwork.artist.isEmpty {
                        Text(artwork.artist)
                            .font(.museumMeta)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }

                    if artwork.hasAudioGuide {
                        AudioGuideView(path: artwork.audioPath, announcedDuration: artwork.audioDuration)
                            .padding(.horizontal)
                    } else if artwork.hasReadAloudGuide {
                        ReadAloudGuideView(html: artwork.text, languageCode: artwork.textLanguageCode)
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
        .navigationTitle(lockedExhibition == nil ? (artwork?.title ?? "") : "")
        .ticketPrompt(for: $promptedExhibition)
        .task {
            isLoadingDetail = true
            await sync.loadArtworkDetailIfNeeded(id: artworkID)
            isLoadingDetail = false
            await sync.loadMapIfNeeded()
        }
    }
}

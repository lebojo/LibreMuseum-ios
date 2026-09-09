import SwiftData
import SwiftUI

struct MapView: View {
    @Environment(ContentSyncService.self) private var sync
    @Query private var museums: [MuseumEntity]
    @Query(
        filter: #Predicate<LanguageEntity> { $0.isActive },
        sort: [SortDescriptor(\LanguageEntity.sort), SortDescriptor(\LanguageEntity.code)]
    )
    private var languages: [LanguageEntity]
    @Query(sort: [SortDescriptor(\FloorEntity.level), SortDescriptor(\FloorEntity.sort)])
    private var floors: [FloorEntity]
    @Query(sort: [SortDescriptor(\RoomEntity.sort), SortDescriptor(\RoomEntity.name)])
    private var rooms: [RoomEntity]
    @Query(sort: [SortDescriptor(\ExhibitionEntity.sort), SortDescriptor(\ExhibitionEntity.slug)])
    private var exhibitions: [ExhibitionEntity]
    @Query(sort: [SortDescriptor(\ArtworkEntity.sort), SortDescriptor(\ArtworkEntity.code)])
    private var artworks: [ArtworkEntity]
    @State private var selectedFloorID = ""
    @State private var selectedPin: MapPinUI?
    @State private var isLoadingMap = false

    private var languageContext: LanguageContext {
        EntityToUI.languageContext(
            museum: museums.first,
            languages: languages,
            selectedCode: sync.selectedLanguageCode
        )
    }

    private var floorItems: [FloorUI] {
        floors.map(EntityToUI.floor)
    }

    private var selectedFloor: FloorUI? {
        floorItems.first { $0.id == selectedFloorID } ?? floorItems.first
    }

    private var floorSelection: Binding<String> {
        Binding(
            get: { selectedFloor?.id ?? "" },
            set: { selectedFloorID = $0 }
        )
    }

    private var roomsOnSelectedFloor: [RoomEntity] {
        guard let selectedFloor else { return [] }
        return rooms.filter { $0.floorID == selectedFloor.id }
    }

    private var pins: [MapPinUI] {
        let roomIDs = Set(roomsOnSelectedFloor.map(\.id))
        let exhibitionsByID = Dictionary(
            exhibitions.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return artworks
            .filter { roomIDs.contains($0.roomID) }
            .compactMap {
                EntityToUI.mapPin(
                    $0,
                    exhibition: exhibitionsByID[$0.exhibitionID],
                    in: languageContext
                )
            }
    }

    private var emptyState: ContentStateView.State {
        if isLoadingMap { return .loading("Loading the floor plans") }
        if case .failed(let message) = sync.state { return .unreachable(message) }
        return .empty("No floor plan", "The museum has not published its floor plans yet.")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.museumMapBackground
                    .ignoresSafeArea()

                if floorItems.isEmpty {
                    ContentStateView(state: emptyState) {
                        Task { await sync.loadMapIfNeeded() }
                    }
                } else if let selectedFloor {
                    if selectedFloor.hasMap {
                        FloorPlanView(
                            mapPath: selectedFloor.mapPath,
                            pins: pins,
                            onSelect: { selectedPin = $0 }
                        )
                        .ignoresSafeArea()
                    } else {
                        ContentStateView(
                            state: .empty("No floor plan", "This floor does not have a plan yet."),
                            onRetry: {}
                        )
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if !floorItems.isEmpty {
                    FloorPickerView(selectedFloorID: floorSelection, floors: floorItems)
                }
            }
            .navigationDestination(item: $selectedPin) { ArtworkDetailView(artworkID: $0.id) }
            .task {
                isLoadingMap = true
                await sync.loadMapIfNeeded()
                await sync.loadExhibitionsIfNeeded()
                await sync.loadEveryArtworkIfNeeded()
                isLoadingMap = false
            }
        }
    }
}

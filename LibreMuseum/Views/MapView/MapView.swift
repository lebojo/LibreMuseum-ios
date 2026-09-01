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
        let exhibitionsByID = Dictionary(uniqueKeysWithValues: exhibitions.map { ($0.id, $0) })
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

    private var roomSections: [RoomArtworksUI] {
        roomsOnSelectedFloor.map { room in
            RoomArtworksUI(
                room: EntityToUI.room(room),
                artworks: artworks
                    .filter { $0.roomID == room.id }
                    .map { EntityToUI.artwork($0, in: languageContext) }
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
            List {
                if floorItems.isEmpty {
                    Section {
                        ContentStateView(state: emptyState) {
                            Task { await sync.loadMapIfNeeded() }
                        }
                    }
                } else {
                    if floorItems.count > 1 {
                        Section {
                            FloorPickerView(selectedFloorID: floorSelection, floors: floorItems)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                    }

                    if let selectedFloor, selectedFloor.hasMap {
                        Section {
                            FloorPlanView(
                                mapPath: selectedFloor.mapPath,
                                pins: pins,
                                onSelect: { selectedPin = $0 }
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                    }

                    ForEach(roomSections) { section in
                        RoomSectionView(section: section)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Map")
            .navigationDestination(item: $selectedPin) { ArtworkDetailView(artworkID: $0.id) }
            .navigationDestination(for: ArtworkUI.self) { ArtworkDetailView(artworkID: $0.id) }
            .refreshable {
                await sync.loadMapIfNeeded()
                await sync.loadEveryArtworkIfNeeded()
            }
            .task {
                isLoadingMap = true
                await sync.loadMapIfNeeded()
                await sync.loadEveryArtworkIfNeeded()
                isLoadingMap = false
            }
        }
    }
}

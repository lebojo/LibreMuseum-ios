import SwiftData
import SwiftUI

struct MuseumMapView: View {
    @Environment(ContentSyncService.self) private var sync
    @Query(sort: [SortDescriptor(\FloorEntity.level), SortDescriptor(\FloorEntity.sort)])
    private var floors: [FloorEntity]
    @State private var selectedFloorID = ""

    private var floorItems: [FloorUI] {
        floors.map(EntityToUI.floor)
    }

    private var selectedFloor: FloorUI? {
        floorItems.first { $0.id == selectedFloorID } ?? floorItems.first
    }

    private var emptyStateReason: MapEmptyStateView.Reason {
        if case .failed(let message) = sync.state { return .unreachable(message) }
        if sync.state == .checking || sync.state == .idle { return .loading }
        return .noFloor
    }

    var body: some View {
        ZStack {
            Color.museumMapBackground
                .ignoresSafeArea()

            if let selectedFloor {
                RemoteFloorPlanView(floor: selectedFloor)
                    .ignoresSafeArea()
            } else {
                MapEmptyStateView(reason: emptyStateReason) {
                    Task { await sync.loadMapIfNeeded() }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if !floorItems.isEmpty {
                FloorPickerView(floors: floorItems, selectedFloorID: $selectedFloorID)
            }
        }
        .onChange(of: floorItems.map(\.id), initial: true) { _, ids in
            if !ids.contains(selectedFloorID) {
                selectedFloorID = ids.first ?? ""
            }
        }
        .task { await sync.loadMapIfNeeded() }
    }
}

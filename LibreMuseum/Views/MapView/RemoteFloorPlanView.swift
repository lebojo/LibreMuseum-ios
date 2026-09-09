import SwiftUI

struct RemoteFloorPlanView: View {
    private enum Phase: Equatable {
        case loading
        case loaded(Data)
        case missing
        case unavailable
    }

    @Environment(\.mediaStore) private var mediaStore
    @State private var phase: Phase = .loading
    @State private var loadAttempt = 0

    let floor: FloorUI

    private var loadID: String {
        "\(floor.mapPath)#\(loadAttempt)"
    }

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView()
                    .controlSize(.large)
            case .loaded(let data):
                ZoomableFloorPlanView(
                    data: data,
                    path: floor.mapPath,
                    accessibilityLabel: floor.name
                )
            case .missing:
                ContentUnavailableView {
                    Label("Floor plan unavailable", systemImage: "map")
                } description: {
                    Text("This floor does not have a plan yet.")
                }
            case .unavailable:
                ContentUnavailableView {
                    Label("Floor plan unavailable", systemImage: "map")
                } description: {
                    Text("The floor plan could not be loaded.")
                } actions: {
                    Button("Try again") { loadAttempt += 1 }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: loadID) { await load() }
    }

    private func load() async {
        guard !floor.mapPath.isEmpty else {
            phase = .missing
            return
        }
        guard let mediaStore else {
            phase = .unavailable
            return
        }

        phase = .loading
        guard let data = await mediaStore.cachedOrDownloadedData(for: floor.mapPath) else {
            phase = .unavailable
            return
        }
        phase = .loaded(data)
    }
}

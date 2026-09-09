import Foundation

nonisolated struct FloorUI: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let level: Int
    let mapPath: String

    var hasMap: Bool { !mapPath.isEmpty }
}

nonisolated struct RoomUI: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let code: String
}

nonisolated struct RoomArtworksUI: Identifiable, Sendable, Hashable {
    let room: RoomUI
    let artworks: [ArtworkUI]

    var id: String { room.id }
}

nonisolated struct MapPinUI: Identifiable, Sendable, Hashable {
    let id: String
    let label: String
    let title: String
    let exhibitionTitle: String
    let colorHex: String
    let relativeX: Double
    let relativeY: Double
}

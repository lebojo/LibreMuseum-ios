import SwiftUI

struct RoomSectionView: View {
    let section: RoomArtworksUI
    let onLocked: (ArtworkUI) -> Void

    var body: some View {
        Section {
            if section.artworks.isEmpty {
                Text("No artwork in this room")
                    .font(.museumCaption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(section.artworks) { artwork in
                    ArtworkLinkView(artwork: artwork) { onLocked(artwork) }
                }
            }
        } header: {
            Text(section.room.name)
        }
    }
}

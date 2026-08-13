import SwiftUI

struct RoomSectionView: View {
    let section: RoomArtworksUI

    var body: some View {
        Section {
            if section.artworks.isEmpty {
                Text("No artwork in this room")
                    .font(.museumCaption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(section.artworks) { artwork in
                    NavigationLink(value: artwork) {
                        ArtworkRowView(artwork: artwork)
                    }
                }
            }
        } header: {
            Text(section.room.name)
        }
    }
}

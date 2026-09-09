import SwiftUI

struct ArtworkRowView: View {
    let artwork: ArtworkUI

    var body: some View {
        if artwork.isLocked {
            LockedArtworkRowView(artwork: artwork)
        } else {
            UnlockedArtworkRowView(artwork: artwork)
        }
    }
}

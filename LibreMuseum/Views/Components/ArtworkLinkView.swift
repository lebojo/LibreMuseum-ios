import SwiftUI

// A locked artwork must not push its own screen: the row keeps its place in the
// list, and the tap asks for the ticket instead. Every list of artworks goes
// through here so that the two behaviours can never drift apart.
struct ArtworkLinkView: View {
    let artwork: ArtworkUI
    let onLocked: () -> Void

    var body: some View {
        if artwork.isLocked {
            Button(action: onLocked) {
                ArtworkRowView(artwork: artwork)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: artwork) {
                ArtworkRowView(artwork: artwork)
            }
        }
    }
}

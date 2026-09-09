import SwiftUI

struct LockedArtworkRowView: View {
    let artwork: ArtworkUI

    var body: some View {
        HStack(spacing: 12) {
            LockedThumbnailView(path: artwork.thumbnailPath)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(LockedTitle.teaser(of: artwork.title))
                .font(.museumHeadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .accessibilityLabel("Locked artwork")

            Spacer(minLength: 0)

            LockBadgeView()
        }
        .padding(.vertical, 2)
    }
}

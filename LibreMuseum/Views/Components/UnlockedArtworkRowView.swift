import SwiftUI

struct UnlockedArtworkRowView: View {
    @Environment(MuseumTheme.self) private var theme

    let artwork: ArtworkUI

    private var attribution: String {
        [artwork.artist, artwork.year]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            RemoteImageView(path: artwork.thumbnailPath, thumb: .square200)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                Text(artwork.title)
                    .font(.museumHeadline)
                    .lineLimit(2)

                if !attribution.isEmpty {
                    Text(attribution)
                        .font(.museumCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if artwork.hasAudioGuide {
                Image(systemName: "headphones")
                    .font(.museumCaption)
                    .foregroundStyle(theme.accent)
                    .accessibilityLabel("Audio guide available")
            }

            if !artwork.code.isEmpty {
                Text(artwork.code)
                    .font(.museumCaption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.vertical, 2)
    }
}

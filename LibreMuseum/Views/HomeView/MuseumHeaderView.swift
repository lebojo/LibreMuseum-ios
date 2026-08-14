import SwiftUI

struct MuseumHeaderView: View {
    @Environment(MuseumTheme.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    let museum: MuseumUI

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !museum.coverPath.isEmpty {
                RemoteImageView(path: museum.coverPath, thumb: .width1200)
                    .frame(height: 200)
            }

            HStack(alignment: .center, spacing: 12) {
                if !museum.logoPath.isEmpty {
                    RemoteImageView(path: museum.logoPath, thumb: .fit120, contentMode: .fit)
                        .frame(width: 48, height: 48)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(museum.name)
                        .font(.museumHeadline)
                        .foregroundStyle(theme.legiblePrimary(on: colorScheme))
                        .accessibilityAddTraits(.isHeader)
                    if !museum.subtitle.isEmpty {
                        Text(museum.subtitle)
                            .font(.museumCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

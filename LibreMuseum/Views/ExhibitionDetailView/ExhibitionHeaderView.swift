import SwiftUI

struct ExhibitionHeaderView: View {
    @Environment(MuseumTheme.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    let exhibition: ExhibitionDetailUI

    private var schedule: ExhibitionScheduleView.Schedule? {
        if exhibition.isPermanent { return .permanent }
        guard let dateRange = exhibition.dateRange else { return nil }
        return .dateRange(dateRange)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !exhibition.coverPath.isEmpty {
                RemoteImageView(path: exhibition.coverPath, thumb: .width1200)
                    .frame(height: 220)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(exhibition.title)
                    .font(.museumTitle)
                    .foregroundStyle(theme.legiblePrimary(on: colorScheme))

                if !exhibition.subtitle.isEmpty {
                    Text(exhibition.subtitle)
                        .font(.museumMeta)
                        .foregroundStyle(.secondary)
                }

                if let schedule {
                    ExhibitionScheduleView(schedule: schedule)
                }

                if exhibition.hasAudioGuide {
                    AudioGuideView(path: exhibition.audioPath)
                        .padding(.top, 4)
                }

                if !exhibition.summary.isEmpty {
                    HTMLTextView(html: exhibition.summary)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
    }
}

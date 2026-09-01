import SwiftUI

struct ExhibitionRowView: View {
    let exhibition: ExhibitionUI

    private var schedule: ExhibitionScheduleView.Schedule? {
        .init(exhibition: exhibition)
    }

    var body: some View {
        HStack(spacing: 12) {
            RemoteImageView(path: exhibition.coverPath, thumb: .card400x300)
                .frame(width: 88, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(exhibition.title)
                    .font(.museumHeadline)
                    .lineLimit(2)

                if !exhibition.subtitle.isEmpty {
                    Text(exhibition.subtitle)
                        .font(.museumCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let schedule {
                    ExhibitionScheduleView(schedule: schedule)
                }
            }
            Spacer(minLength: 0)

            if exhibition.isLocked {
                LockBadgeView()
            }
        }
        .padding(.vertical, 4)
    }
}

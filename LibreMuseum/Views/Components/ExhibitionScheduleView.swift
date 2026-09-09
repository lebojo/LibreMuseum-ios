import SwiftUI

struct ExhibitionScheduleView: View {
    enum Schedule: Equatable {
        case permanent
        case dateRange(String)

        init?(exhibition: ExhibitionUI) {
            if exhibition.isPermanent {
                self = .permanent
            } else if let dateRange = exhibition.dateRange {
                self = .dateRange(dateRange)
            } else {
                return nil
            }
        }
    }

    @Environment(MuseumTheme.self) private var theme

    let schedule: Schedule

    var body: some View {
        Group {
            switch schedule {
            case .permanent:
                Text("Permanent collection")
            case .dateRange(let dateRange):
                Text(dateRange)
            }
        }
        .font(.museumCaption)
        .foregroundStyle(theme.accent)
    }
}

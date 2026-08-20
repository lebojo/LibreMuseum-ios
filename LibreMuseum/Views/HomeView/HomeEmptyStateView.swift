import SwiftUI

struct HomeEmptyStateView: View {
    enum Reason: Equatable {
        case unreachable(String)
        case loading
        case noExhibition

        var titleKey: LocalizedStringKey {
            switch self {
            case .unreachable: "Museum unreachable"
            case .loading: "Loading the museum"
            case .noExhibition: "No exhibitions"
            }
        }

        var symbolName: String {
            switch self {
            case .unreachable: "wifi.exclamationmark"
            case .loading: "building.columns"
            case .noExhibition: "photo.on.rectangle.angled"
            }
        }
    }

    let reason: Reason
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(reason.titleKey, systemImage: reason.symbolName)
        } description: {
            switch reason {
            case .unreachable(let message):
                Text(message)
            case .loading:
                Text("Fetching content from the server.")
            case .noExhibition:
                Text("The museum has not published any exhibition yet.")
            }
        } actions: {
            if case .unreachable = reason {
                Button("Try again", action: onRetry)
            }
        }
    }
}

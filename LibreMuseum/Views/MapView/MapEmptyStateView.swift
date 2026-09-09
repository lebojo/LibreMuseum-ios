import SwiftUI

struct MapEmptyStateView: View {
    enum Reason: Equatable {
        case unreachable(String)
        case loading
        case noFloor

        var titleKey: LocalizedStringKey {
            switch self {
            case .unreachable: "Museum unreachable"
            case .loading: "Loading the map"
            case .noFloor: "No floor plans"
            }
        }

        var symbolName: String {
            switch self {
            case .unreachable: "wifi.exclamationmark"
            case .loading: "map"
            case .noFloor: "map"
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
            case .noFloor:
                Text("The museum has not published any floor plan yet.")
            }
        } actions: {
            if case .unreachable = reason {
                Button("Try again", action: onRetry)
            }
        }
    }
}

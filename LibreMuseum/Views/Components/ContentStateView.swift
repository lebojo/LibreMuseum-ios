import SwiftUI

struct ContentStateView: View {
    enum State: Equatable {
        case loading(LocalizedStringKey)
        case unreachable(String)
        case empty(LocalizedStringKey, LocalizedStringKey)

        var symbolName: String {
            switch self {
            case .loading: "arrow.triangle.2.circlepath"
            case .unreachable: "wifi.exclamationmark"
            case .empty: "tray"
            }
        }
    }

    let state: State
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            switch state {
            case .loading(let title):
                Label(title, systemImage: state.symbolName)
            case .unreachable:
                Label("Museum unreachable", systemImage: state.symbolName)
            case .empty(let title, _):
                Label(title, systemImage: state.symbolName)
            }
        } description: {
            switch state {
            case .loading:
                Text("Fetching content from the server.")
            case .unreachable(let message):
                Text(message)
            case .empty(_, let detail):
                Text(detail)
            }
        } actions: {
            if case .unreachable = state {
                Button("Try again", action: onRetry)
            }
        }
    }
}

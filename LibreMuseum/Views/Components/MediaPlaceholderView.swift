import SwiftUI

struct MediaPlaceholderView: View {
    enum Reason: Equatable {
        case loading
        case unavailable
    }

    let reason: Reason

    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                switch reason {
                case .loading:
                    ProgressView().controlSize(.small)
                case .unavailable:
                    Image(systemName: "photo")
                        .foregroundStyle(.tertiary)
                }
            }
    }
}

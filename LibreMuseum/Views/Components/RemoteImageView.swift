import SwiftUI

struct RemoteImageView: View {
    private enum Phase: Equatable {
        case loading
        case loaded(UIImage)
        case unavailable
    }

    @Environment(\.mediaStore) private var mediaStore

    @State private var phase: Phase = .loading

    let path: String
    let thumb: ThumbSize?
    var contentMode: ContentMode = .fill

    private var cacheKey: String {
        MediaAssetEntity.cacheKey(path: path, thumb: thumb)
    }

    var body: some View {
        Group {
            switch phase {
            case .loading:
                MediaPlaceholderView(reason: .loading)
            case .loaded(let image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .unavailable:
                MediaPlaceholderView(reason: .unavailable)
            }
        }
        .clipped()
        .task(id: cacheKey) { await load() }
    }

    private func load() async {
        guard !path.isEmpty, let mediaStore else {
            phase = .unavailable
            return
        }
        phase = .loading

        guard let data = await mediaStore.cachedOrDownloadedData(for: path, thumb: thumb) else {
            phase = .unavailable
            return
        }

        guard let image = UIImage(data: data) else {
            phase = .unavailable
            return
        }
        phase = .loaded(image)
    }
}

import SwiftUI

struct ArtworkGalleryView: View {
    let imagePaths: [String]

    var body: some View {
        TabView {
            ForEach(imagePaths, id: \.self) { path in
                RemoteImageView(path: path, thumb: .width800, contentMode: .fit)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: imagePaths.count > 1 ? .automatic : .never))
        .frame(height: 320)
        .background(.quaternary)
    }
}

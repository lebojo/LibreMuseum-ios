import SwiftUI

struct LockedThumbnailView: View {
    let path: String
    var thumb: ThumbSize? = .square200
    var blurRadius: CGFloat = 6

    var body: some View {
        RemoteImageView(path: path, thumb: thumb)
            .blur(radius: blurRadius)
            // The blur samples pixels from outside the frame, which would show a
            // translucent fringe: the clip has to come after it, not before.
            .clipped()
            .overlay { Color.black.opacity(0.15) }
            .overlay { LockBadgeView(font: .museumHeadline) }
            .accessibilityElement()
            .accessibilityLabel("Locked image")
    }
}

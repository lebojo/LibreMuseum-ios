import SwiftUI

struct FloorPlanView: View {
    @State private var planSize: CGSize?
    @State private var scale: CGFloat = 1
    @State private var offset = CGSize.zero
    @GestureState private var magnification: CGFloat = 1
    @GestureState private var dragTranslation = CGSize.zero

    let mapPath: String
    let pins: [MapPinUI]
    let onSelect: (MapPinUI) -> Void

    private let maximumScale: CGFloat = 8

    private var aspectRatio: Double {
        guard let planSize, planSize.height > 0 else { return 4.0 / 3.0 }
        return planSize.width / planSize.height
    }

    var body: some View {
        GeometryReader { proxy in
            let fittedSize = fittedSize(in: proxy.size)
            let displayedScale = min(max(scale * magnification, 1), maximumScale)
            let proposedOffset = CGSize(
                width: offset.width + dragTranslation.width,
                height: offset.height + dragTranslation.height
            )
            let displayedOffset = constrainedOffset(
                proposedOffset,
                scale: displayedScale,
                viewportSize: proxy.size,
                contentSize: fittedSize
            )

            ZStack(alignment: .topLeading) {
                RemoteImageView(path: mapPath, thumb: nil, contentMode: .fit) { size in
                    planSize = size
                }

                ForEach(pins) { pin in
                    Button {
                        onSelect(pin)
                    } label: {
                        MapPinView(
                            label: pin.label,
                            colorHex: pin.colorHex,
                            isLocked: pin.isLocked
                        )
                    }
                    .buttonStyle(.plain)
                    .offset(
                        x: pin.relativeX * fittedSize.width - MapPinView.diameter / 2,
                        y: pin.relativeY * fittedSize.height - MapPinView.diameter / 2
                    )
                    .accessibilityLabel(
                        pin.isLocked
                            ? Text("Locked artwork")
                            : Text(
                                verbatim: [pin.title, pin.exhibitionTitle]
                                    .filter { !$0.isEmpty }
                                    .joined(separator: ", ")
                            )
                    )
                }
            }
            .frame(width: fittedSize.width, height: fittedSize.height)
            .scaleEffect(displayedScale)
            .offset(displayedOffset)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(
                MagnifyGesture()
                    .updating($magnification) { value, gestureScale, _ in
                        gestureScale = value.magnification
                    }
                    .onEnded { value in
                        scale = min(max(scale * value.magnification, 1), maximumScale)
                        offset = constrainedOffset(
                            offset,
                            scale: scale,
                            viewportSize: proxy.size,
                            contentSize: fittedSize
                        )
                    }
                    .simultaneously(
                        with: DragGesture()
                            .updating($dragTranslation) { value, translation, _ in
                                translation = value.translation
                            }
                            .onEnded { value in
                                let proposedOffset = CGSize(
                                    width: offset.width + value.translation.width,
                                    height: offset.height + value.translation.height
                                )
                                offset = constrainedOffset(
                                    proposedOffset,
                                    scale: scale,
                                    viewportSize: proxy.size,
                                    contentSize: fittedSize
                                )
                            }
                    )
            )
        }
        .clipped()
        .onChange(of: mapPath) {
            scale = 1
            offset = .zero
        }
    }

    private func fittedSize(in viewportSize: CGSize) -> CGSize {
        guard viewportSize.width > 0, viewportSize.height > 0 else { return .zero }
        if viewportSize.width / viewportSize.height > aspectRatio {
            return CGSize(width: viewportSize.height * aspectRatio, height: viewportSize.height)
        }
        return CGSize(width: viewportSize.width, height: viewportSize.width / aspectRatio)
    }

    private func constrainedOffset(
        _ proposedOffset: CGSize,
        scale: CGFloat,
        viewportSize: CGSize,
        contentSize: CGSize
    ) -> CGSize {
        let horizontalLimit = max((contentSize.width * scale - viewportSize.width) / 2, 0)
        let verticalLimit = max((contentSize.height * scale - viewportSize.height) / 2, 0)
        return CGSize(
            width: min(max(proposedOffset.width, -horizontalLimit), horizontalLimit),
            height: min(max(proposedOffset.height, -verticalLimit), verticalLimit)
        )
    }
}

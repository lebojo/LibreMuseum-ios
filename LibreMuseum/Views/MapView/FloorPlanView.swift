import SwiftUI

struct FloorPlanView: View {
    @State private var planSize: CGSize?
    @State private var renderedSize: CGSize = .zero

    let mapPath: String
    let pins: [MapPinUI]

    private var aspectRatio: Double {
        guard let planSize, planSize.height > 0 else { return 4.0 / 3.0 }
        return planSize.width / planSize.height
    }

    var body: some View {
        RemoteImageView(path: mapPath, thumb: .width1600, contentMode: .fit) { size in
            planSize = size
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { renderedSize = $0 }
        .overlay(alignment: .topLeading) {
            if renderedSize.width > 0 {
                ForEach(pins) { pin in
                    NavigationLink(value: pin) {
                        MapPinView(label: pin.label)
                    }
                    .buttonStyle(.plain)
                    .offset(
                        x: pin.relativeX * renderedSize.width - MapPinView.diameter / 2,
                        y: pin.relativeY * renderedSize.height - MapPinView.diameter / 2
                    )
                    .accessibilityLabel(pin.title)
                }
            }
        }
    }
}

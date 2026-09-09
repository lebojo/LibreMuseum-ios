import SwiftUI

struct FloorPickerView: View {
    @Binding var selectedFloorID: String

    let floors: [FloorUI]

    var body: some View {
        Picker("Floor", selection: $selectedFloorID) {
            ForEach(floors) { floor in
                Text(floor.name)
                    .lineLimit(1)
                    .tag(floor.id)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 520)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }
}

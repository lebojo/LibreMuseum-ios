import SwiftUI

struct FloorPickerView: View {
    @Binding var selectedFloorID: String

    let floors: [FloorUI]

    var body: some View {
        Picker("Floor", selection: $selectedFloorID) {
            ForEach(floors) { floor in
                Text(floor.name).tag(floor.id)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

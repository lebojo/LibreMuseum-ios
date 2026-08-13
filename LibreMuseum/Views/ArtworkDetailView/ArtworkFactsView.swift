import SwiftUI

struct ArtworkFactsView: View {
    let artwork: ArtworkDetailUI

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !artwork.year.isEmpty {
                LabeledContent("Date", value: artwork.year)
            }
            if !artwork.technique.isEmpty {
                LabeledContent("Technique", value: artwork.technique)
            }
            if !artwork.roomName.isEmpty {
                LabeledContent("Room", value: artwork.roomName)
            }
            if !artwork.code.isEmpty {
                LabeledContent("Label number", value: artwork.code)
            }
            if !artwork.inventoryNumber.isEmpty {
                LabeledContent("Inventory number", value: artwork.inventoryNumber)
            }
        }
        .font(.museumCaption)
        .padding(.horizontal)
    }
}

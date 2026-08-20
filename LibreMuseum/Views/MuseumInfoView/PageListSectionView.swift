import SwiftUI

struct PageListSectionView: View {
    let pages: [PageUI]

    var body: some View {
        Section("Visit") {
            ForEach(pages) { page in
                NavigationLink(value: page) {
                    Label(page.title, systemImage: page.symbolName)
                }
            }
        }
    }
}

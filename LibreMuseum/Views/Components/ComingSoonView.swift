import SwiftUI

struct ComingSoonView: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "hammer")
        } description: {
            Text(detail)
        }
    }
}

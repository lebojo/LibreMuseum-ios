import SwiftUI

struct PageDetailView: View {
    let page: PageDetailUI

    var body: some View {
        ScrollView {
            HTMLTextView(html: page.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(page.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(MuseumTheme.self) private var theme
    @Query private var museums: [MuseumEntity]

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }

            Tab("Map", systemImage: "map") {
                MuseumMapView()
            }

            Tab(role: .search) {
                ComingSoonView(
                    title: "Search",
                    detail: "Search by title, artist and medium will appear here."
                )
            }
        }
        .tint(theme.accent)
        .task(id: museums.first?.primaryColorHex) { applyTheme() }
        .task(id: museums.first?.accentColorHex) { applyTheme() }
    }

    private func applyTheme() {
        guard let museum = museums.first else {
            theme.reset()
            return
        }
        theme.apply(primaryHex: museum.primaryColorHex, accentHex: museum.accentColorHex)
    }
}

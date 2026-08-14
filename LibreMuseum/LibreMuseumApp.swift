import SwiftData
import SwiftUI

@main
struct LibreMuseumApp: App {
    @State private var sync: ContentSyncService
    @State private var theme = MuseumTheme()

    private let modelContainer: ModelContainer
    private let mediaStore: MediaStore

    init() {
        let container = Self.makeModelContainer()
        let store = MediaStore(modelContainer: container)

        modelContainer = container
        mediaStore = store
        _sync = State(initialValue: ContentSyncService(modelContainer: container, mediaStore: store))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sync)
                .environment(theme)
                .environment(\.mediaStore, mediaStore)
        }
        .modelContainer(modelContainer)
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            MuseumEntity.self,
            LanguageEntity.self,
            FloorEntity.self,
            RoomEntity.self,
            ExhibitionEntity.self,
            ExhibitionTranslationEntity.self,
            ArtworkEntity.self,
            ArtworkTranslationEntity.self,
            PageEntity.self,
            PageTranslationEntity.self,
            MediaAssetEntity.self,
            SyncStateEntity.self,
        ])

        try? FileManager.default.createDirectory(
            at: URL.applicationSupportDirectory,
            withIntermediateDirectories: true
        )

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            removeStoreFiles(at: configuration.url)
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Cannot create the local store: \(error)")
            }
        }
    }

    private static func removeStoreFiles(at url: URL) {
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(filePath: url.path() + suffix))
        }
    }
}

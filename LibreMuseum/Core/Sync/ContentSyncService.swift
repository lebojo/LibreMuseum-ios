import Foundation
import SwiftData

@Observable
@MainActor
final class ContentSyncService {
    enum State: Equatable {
        case idle
        case checking
        case ready
        case prefetching(progress: Double)
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var contentVersion = ""
    private(set) var lastCheckedAt: Date?
    private(set) var storageBytes = 0
    private(set) var selectedLanguageCode = ""
    private let client: PocketBaseClientProtocol
    private let importer: ContentImporter
    private let mediaStore: MediaStore
    private let repository: ContentRepository
    private let context: ModelContext

    init(modelContainer: ModelContainer) {
        let client = PocketBaseClient()
        let importer = ContentImporter(modelContainer: modelContainer)
        let context = ModelContext(modelContainer)

        self.client = client
        self.importer = importer
        self.mediaStore = MediaStore(modelContainer: modelContainer)
        self.context = context
        self.repository = ContentRepository(
            client: client,
            importer: importer,
            context: context
        )
    }

    func start() async {
        loadLocalState()
        await checkVersion()
        await loadShellIfNeeded()
        await loadExhibitionsIfNeeded()
        await refreshStorage()
    }

    func checkVersion() async {
        state = .checking
        do {
            let remote = try await client.contentVersion()
            let now = Date.now
            try await importer.updateSyncState(version: remote, checkedAt: now)
            contentVersion = remote
            lastCheckedAt = now
            state = .ready
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    func loadShellIfNeeded() async {
        let stale = repository.needsRefresh(MuseumEntity.self, version: contentVersion) {
            $0.fetchedVersion != contentVersion
        }
        let languagesStale = repository.needsRefresh(LanguageEntity.self, version: contentVersion) {
            $0.fetchedVersion != contentVersion
        }
        guard stale || languagesStale else { return }
        await runIgnoringNetworkFailure { try await self.repository.loadShell(version: self.contentVersion) }
    }

    func loadExhibitionsIfNeeded() async {
        let stale = repository.needsRefresh(ExhibitionEntity.self, version: contentVersion) {
            $0.fetchedVersion != contentVersion
        }
        guard stale else { return }
        await runIgnoringNetworkFailure { try await self.repository.loadExhibitions(version: self.contentVersion) }
    }

    func loadMapIfNeeded() async {
        let stale = repository.needsRefresh(FloorEntity.self, version: contentVersion) {
            $0.fetchedVersion != contentVersion
        }
        guard stale else { return }
        await runIgnoringNetworkFailure { try await self.repository.loadMap(version: self.contentVersion) }
    }

    func loadArtworksIfNeeded(exhibitionID: String) async {
        guard repository.needsArtworks(exhibitionID: exhibitionID, version: contentVersion) else {
            return
        }
        await runIgnoringNetworkFailure {
            try await self.repository.loadArtworks(
                exhibitionID: exhibitionID,
                version: self.contentVersion
            )
        }
    }

    func reloadArtworks(exhibitionID: String) async {
        await runIgnoringNetworkFailure {
            try await self.repository.loadArtworks(
                exhibitionID: exhibitionID,
                version: self.contentVersion
            )
        }
    }

    func loadEveryArtworkIfNeeded() async {
        for id in repository.cachedExhibitionIDs() {
            await loadArtworksIfNeeded(exhibitionID: id)
        }
    }

    func loadArtworkDetailIfNeeded(id: String) async {
        guard repository.needsArtworkFullText(id: id, version: contentVersion) else { return }
        do {
            try await repository.loadArtworkDetail(id: id, version: contentVersion)
            state = .ready
        } catch let error as APIError where error.isContentRemovedFromServer {
            try? await importer.deleteArtwork(id: id)
            state = .ready
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    func prefetchAll() async {
        await runIgnoringNetworkFailure { try await self.repository.loadShell(version: self.contentVersion) }
        await runIgnoringNetworkFailure { try await self.repository.loadExhibitions(version: self.contentVersion) }
        await runIgnoringNetworkFailure { try await self.repository.loadMap(version: self.contentVersion) }

        let exhibitionIDs = (try? context.fetch(FetchDescriptor<ExhibitionEntity>()))?
            .map(\.id) ?? []
        for id in exhibitionIDs {
            await runIgnoringNetworkFailure {
                try await self.repository.loadArtworks(
                    exhibitionID: id,
                    version: self.contentVersion
                )
            }
        }

        state = .prefetching(progress: 0)

        await mediaStore.prefetchAll { progress in
            Task { @MainActor in self.state = .prefetching(progress: progress) }
        }
        state = .ready
        await refreshStorage()
    }

    func purgeAll() async {
        do {
            try await mediaStore.purge()
            try await importer.purgeAll()
            contentVersion = ""
            lastCheckedAt = nil
            state = .idle
        } catch {
            state = .failed(Self.message(for: error))
        }
        await refreshStorage()
    }

    func selectLanguage(_ code: String) async {
        selectedLanguageCode = code
        try? await importer.updateSelectedLanguage(code)
    }

    func refreshStorage() async {
        storageBytes = await mediaStore.totalBytes()
    }

    private func loadLocalState() {
        var descriptor = FetchDescriptor<SyncStateEntity>()
        descriptor.fetchLimit = 1
        guard let state = try? context.fetch(descriptor).first else { return }
        contentVersion = state.contentVersion
        lastCheckedAt = state.lastCheckedAt
        selectedLanguageCode = state.selectedLanguageCode
    }

    private func runIgnoringNetworkFailure(_ operation: () async throws -> Void) async {
        do {
            try await operation()
            state = .ready
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? APIError)?.errorDescription ?? error.localizedDescription
    }
}

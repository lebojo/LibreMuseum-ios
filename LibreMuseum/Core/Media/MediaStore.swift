import Foundation
import SwiftData

@ModelActor
actor MediaStore {
    private var client: PocketBaseClientProtocol = PocketBaseClient()
    private var inFlight: [String: Task<Data?, Never>] = [:]

    func setClient(_ client: PocketBaseClientProtocol) {
        self.client = client
    }

    func cachedOrDownloadedData(for path: String, thumb: ThumbSize? = nil) async -> Data? {
        guard !path.isEmpty else { return nil }
        let key = MediaAssetEntity.cacheKey(path: path, thumb: thumb)

        if let cached = cachedData(key: key) { return cached }
        if let running = inFlight[key] { return await running.value }

        let task = Task<Data?, Never> { [client] in
            try? await client.media(path: path, thumb: thumb)
        }
        inFlight[key] = task
        let data = await task.value
        inFlight[key] = nil

        if let data { persist(key: key, path: path, data: data) }
        return data
    }

    func prefetchAll(progress: @Sendable (Double) -> Void) async {
        let paths = allReferencedMediaRequests()
        guard !paths.isEmpty else {
            progress(1)
            return
        }
        for (index, request) in paths.enumerated() {
            _ = await cachedOrDownloadedData(for: request.path, thumb: request.thumb)
            progress(Double(index + 1) / Double(paths.count))
        }
    }

    func purge() throws {
        try modelContext.delete(model: MediaAssetEntity.self)
        try modelContext.save()
    }

    func totalBytes() -> Int {
        var descriptor = FetchDescriptor<MediaAssetEntity>()
        descriptor.propertiesToFetch = [\.byteCount]
        let assets = (try? modelContext.fetch(descriptor)) ?? []
        return assets.reduce(0) { $0 + $1.byteCount }
    }

    private func cachedData(key: String) -> Data? {
        var descriptor = FetchDescriptor<MediaAssetEntity>(
            predicate: #Predicate { $0.cacheKey == key }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first?.data
    }

    private func persist(key: String, path: String, data: Data) {
        modelContext.insert(MediaAssetEntity(cacheKey: key, path: path, data: data))
        try? modelContext.save()
    }

    private func allReferencedMediaRequests() -> [MediaRequest] {
        var requests: [MediaRequest] = []
        let museums = (try? modelContext.fetch(FetchDescriptor<MuseumEntity>())) ?? []
        for museum in museums {
            requests.append(MediaRequest(path: museum.logoPath, thumb: .fit512))
            requests.append(MediaRequest(path: museum.coverPath, thumb: .width1200))
        }

        let floors = (try? modelContext.fetch(FetchDescriptor<FloorEntity>())) ?? []
        for floor in floors {
            requests.append(MediaRequest(path: floor.mapPath, thumb: nil))
        }

        let exhibitions = (try? modelContext.fetch(FetchDescriptor<ExhibitionEntity>())) ?? []
        for exhibition in exhibitions {
            requests.append(MediaRequest(path: exhibition.coverPath, thumb: .card400x300))
            requests.append(MediaRequest(path: exhibition.coverPath, thumb: .width1200))
            for translation in exhibition.translations {
                requests.append(MediaRequest(path: translation.audioPath, thumb: nil))
            }
        }

        let artworks = (try? modelContext.fetch(FetchDescriptor<ArtworkEntity>())) ?? []
        for artwork in artworks {
            for (index, path) in artwork.imagePaths.enumerated() {
                if index == 0 {
                    requests.append(MediaRequest(path: path, thumb: .square200))
                }
                requests.append(MediaRequest(path: path, thumb: .width800))
            }
            for translation in artwork.translations {
                requests.append(MediaRequest(path: translation.audioPath, thumb: nil))
            }
        }

        var seen = Set<String>()
        return requests.filter { request in
            guard !request.path.isEmpty else { return false }
            return seen.insert(request.cacheKey).inserted
        }
    }

    private struct MediaRequest {
        let path: String
        let thumb: ThumbSize?

        var cacheKey: String { MediaAssetEntity.cacheKey(path: path, thumb: thumb) }
    }
}

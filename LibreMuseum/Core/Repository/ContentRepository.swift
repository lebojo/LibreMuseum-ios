import Foundation
import SwiftData

@MainActor
protocol ContentRepositoryProtocol {
    func loadShell(version: String) async throws
    func loadExhibitions(version: String) async throws
    func loadMap(version: String) async throws
    func loadArtworks(exhibitionID: String, version: String) async throws
    func loadArtworkDetail(id: String, version: String) async throws
}

@MainActor
final class ContentRepository: ContentRepositoryProtocol {
    private let client: PocketBaseClientProtocol
    private let importer: ContentImporter
    private let context: ModelContext
    private static let pageSize = 100

    init(client: PocketBaseClientProtocol, importer: ContentImporter, context: ModelContext) {
        self.client = client
        self.importer = importer
        self.context = context
    }

    private func everyPage<Item: Decodable & Sendable>(
        of collection: PocketBaseCollection,
        query makeQuery: (Int) -> PocketBaseQuery
    ) async throws -> [Item] {
        var items: [Item] = []
        var page = 1

        while true {
            let response: PocketBaseListResponse<Item> = try await client.list(
                collection,
                query: makeQuery(page)
            )
            items.append(contentsOf: response.items)
            guard response.hasMorePages else { break }
            page += 1
        }
        return items
    }

    func loadShell(version: String) async throws {
        let languages: [LanguageDTO] = try await everyPage(of: .language) {
            PocketBaseQuery(page: $0, perPage: Self.pageSize, sort: "sort,code", skipTotal: true)
        }
        try await importer.importLanguages(languages, version: version)

        let museums: PocketBaseListResponse<MuseumDTO> = try await client.list(
            .museum,
            query: .singleton
        )

        if let museum = museums.items.first {
            try await importer.importMuseum(museum, version: version)
        }

        let pages: [PageDTO] = try await everyPage(of: .page) {
            PocketBaseQuery(page: $0, perPage: Self.pageSize, sort: "sort,slug", skipTotal: true)
        }
        let pageTranslations: [PageTranslationDTO] = try await everyPage(of: .pageTranslation) {
            PocketBaseQuery(page: $0, perPage: Self.pageSize, skipTotal: true)
        }
        try await importer.importPages(
            pages,
            translations: pageTranslations,
            version: version,
            isCompleteSet: true
        )
    }

    func loadExhibitions(version: String) async throws {
        let exhibitions: [ExhibitionDTO] = try await everyPage(of: .exhibition) {
            PocketBaseQuery(page: $0, perPage: Self.pageSize, sort: "sort,slug", skipTotal: true)
        }
        let translations: [ExhibitionTranslationDTO] = try await everyPage(
            of: .exhibitionTranslation
        ) {
            PocketBaseQuery(page: $0, perPage: Self.pageSize, skipTotal: true)
        }

        try await importer.importExhibitions(
            exhibitions,
            translations: translations,
            version: version,
            isCompleteSet: true
        )
    }

    func loadMap(version: String) async throws {
        let floors: [FloorDTO] = try await everyPage(of: .floor) {
            PocketBaseQuery(page: $0, perPage: Self.pageSize, sort: "level", skipTotal: true)
        }
        let rooms: [RoomDTO] = try await everyPage(of: .room) {
            PocketBaseQuery(page: $0, perPage: Self.pageSize, sort: "sort,name", skipTotal: true)
        }
        try await importer.importMap(floors: floors, rooms: rooms, version: version)
    }

    func loadArtworks(exhibitionID: String, version: String) async throws {
        let quoted = PocketBaseQuery.quotedFilterValue(exhibitionID)

        let artworks: [ArtworkDTO] = try await everyPage(of: .artwork) {
            PocketBaseQuery(
                page: $0,
                perPage: Self.pageSize,
                filter: "(exhibition=\(quoted))",
                sort: "sort,code",
                skipTotal: true
            )
        }
        let translations: [ArtworkTranslationDTO] = try await everyPage(of: .artworkTranslation) {
            PocketBaseQuery(
                page: $0,
                perPage: Self.pageSize,
                filter: "(artwork.exhibition=\(quoted))",
                fields: "id,collectionName,artwork,language,title,audio,audio_duration",
                skipTotal: true
            )
        }

        try await importer.importArtworks(
            artworks,
            translations: translations,
            version: version,
            includesFullText: false,
            isCompleteSet: true
        )
        try await importer.pruneArtworks(exhibitionID: exhibitionID, keeping: artworks.map(\.id))
    }

    func loadArtworkDetail(id: String, version: String) async throws {
        let artwork: ArtworkDTO = try await client.record(.artwork, id: id, query: PocketBaseQuery())
        let quoted = PocketBaseQuery.quotedFilterValue(id)
        let translations: [ArtworkTranslationDTO] = try await everyPage(of: .artworkTranslation) {
            PocketBaseQuery(
                page: $0,
                perPage: Self.pageSize,
                filter: "(artwork=\(quoted))",
                skipTotal: true
            )
        }
        try await importer.importArtworks(
            [artwork],
            translations: translations,
            version: version,
            includesFullText: true,
            isCompleteSet: true
        )
    }

    func needsRefresh<Entity: PersistentModel>(
        _ type: Entity.Type,
        version: String,
        isStale: (Entity) -> Bool
    ) -> Bool {
        guard let entities = try? context.fetch(FetchDescriptor<Entity>()) else { return true }
        if entities.isEmpty { return true }
        return entities.contains(where: isStale)
    }

    func needsArtworks(exhibitionID: String, version: String) -> Bool {
        let descriptor = FetchDescriptor<ArtworkEntity>(
            predicate: #Predicate { $0.exhibitionID == exhibitionID }
        )
        guard let artworks = try? context.fetch(descriptor) else { return true }
        if artworks.isEmpty { return true }
        return artworks.contains { $0.fetchedVersion != version }
    }

    func needsArtworkFullText(id: String, version: String) -> Bool {
        var descriptor = FetchDescriptor<ArtworkEntity>(predicate: ArtworkEntity.predicate(id: id))
        descriptor.fetchLimit = 1
        guard let artwork = try? context.fetch(descriptor).first else { return true }
        return artwork.fullTextVersion != version
    }

    func cachedExhibitionIDs() -> [String] {
        let descriptor = FetchDescriptor<ExhibitionEntity>(
            sortBy: [SortDescriptor(\.sort), SortDescriptor(\.slug)]
        )
        return ((try? context.fetch(descriptor)) ?? []).map(\.id)
    }
}

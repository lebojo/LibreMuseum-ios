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

    func loadShell(version: String) async throws {
        let languages: PocketBaseListResponse<LanguageDTO> = try await client.list(
            .language,
            query: PocketBaseQuery(perPage: 200, sort: "sort,code", skipTotal: true)
        )
        try await importer.importLanguages(languages.items, version: version)

        let museums: PocketBaseListResponse<MuseumDTO> = try await client.list(
            .museum,
            query: .singleton
        )

        if let museum = museums.items.first {
            try await importer.importMuseum(museum, version: version)
        }

        let pages: PocketBaseListResponse<PageDTO> = try await client.list(
            .page,
            query: PocketBaseQuery(perPage: 200, sort: "sort,slug", skipTotal: true)
        )
        let pageTranslations: PocketBaseListResponse<PageTranslationDTO> = try await client.list(
            .pageTranslation,
            query: PocketBaseQuery(perPage: 500, skipTotal: true)
        )
        try await importer.importPages(
            pages.items,
            translations: pageTranslations.items,
            version: version
        )
    }

    func loadExhibitions(version: String) async throws {
        var all: [ExhibitionDTO] = []
        var page = 1

        while true {
            let response: PocketBaseListResponse<ExhibitionDTO> = try await client.list(
                .exhibition,
                query: PocketBaseQuery(
                    page: page,
                    perPage: Self.pageSize,
                    sort: "sort,slug",
                    skipTotal: true
                )
            )
            all.append(contentsOf: response.items)
            guard response.hasMorePages else { break }
            page += 1
        }

        let translations: PocketBaseListResponse<ExhibitionTranslationDTO> = try await client.list(
            .exhibitionTranslation,
            query: PocketBaseQuery(perPage: PocketBaseQuery.maxPerPage, skipTotal: true)
        )

        try await importer.importExhibitions(
            all,
            translations: translations.items,
            version: version,
            isCompleteSet: true
        )
    }

    func loadMap(version: String) async throws {
        let floors: PocketBaseListResponse<FloorDTO> = try await client.list(
            .floor,
            query: PocketBaseQuery(perPage: 100, sort: "level", skipTotal: true)
        )
        let rooms: PocketBaseListResponse<RoomDTO> = try await client.list(
            .room,
            query: PocketBaseQuery(perPage: PocketBaseQuery.maxPerPage, sort: "sort,name", skipTotal: true)
        )
        try await importer.importMap(floors: floors.items, rooms: rooms.items, version: version)
    }

    func loadArtworks(exhibitionID: String, version: String) async throws {
        let quoted = PocketBaseQuery.quotedFilterValue(exhibitionID)
        var all: [ArtworkDTO] = []
        var page = 1

        while true {
            let response: PocketBaseListResponse<ArtworkDTO> = try await client.list(
                .artwork,
                query: PocketBaseQuery(
                    page: page,
                    perPage: Self.pageSize,
                    filter: "(exhibition=\(quoted))",
                    sort: "sort,code",
                    skipTotal: true
                )
            )
            all.append(contentsOf: response.items)
            guard response.hasMorePages else { break }
            page += 1
        }

        let translations: PocketBaseListResponse<ArtworkTranslationDTO> = try await client.list(
            .artworkTranslation,
            query: PocketBaseQuery(
                perPage: PocketBaseQuery.maxPerPage,
                filter: "(artwork.exhibition=\(quoted))",
                fields: "id,collectionName,artwork,language,title,audio,audio_duration",
                skipTotal: true
            )
        )

        try await importer.importArtworks(
            all,
            translations: translations.items,
            version: version,
            includesFullText: false
        )
        try await importer.pruneArtworks(exhibitionID: exhibitionID, keeping: all.map(\.id))
    }

    func loadArtworkDetail(id: String, version: String) async throws {
        let artwork: ArtworkDTO = try await client.record(.artwork, id: id, query: PocketBaseQuery())
        let translations: PocketBaseListResponse<ArtworkTranslationDTO> = try await client.list(
            .artworkTranslation,
            query: PocketBaseQuery(
                perPage: 50,
                filter: "(artwork=\(PocketBaseQuery.quotedFilterValue(id)))",
                skipTotal: true
            )
        )
        try await importer.importArtworks(
            [artwork],
            translations: translations.items,
            version: version,
            includesFullText: true
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
}

import Foundation
import SwiftData

@ModelActor
actor ContentImporter {
    func importMuseum(_ dto: MuseumDTO, version: String) throws {
        let entity = try upsert(MuseumEntity.self, id: dto.id) { MuseumEntity(id: dto.id) }
        entity.name = dto.name
        entity.subtitle = dto.subtitle
        entity.logoPath = dto.logoPath ?? ""
        entity.coverPath = dto.coverPath ?? ""
        entity.primaryColorHex = dto.primaryColor
        entity.accentColorHex = dto.accentColor
        entity.defaultLanguageID = dto.defaultLanguageID
        entity.website = dto.website
        entity.email = dto.email
        entity.phone = dto.phone
        entity.address = dto.address
        entity.latitude = dto.latitude
        entity.longitude = dto.longitude
        entity.fetchedVersion = version
        try modelContext.save()
    }

    func importLanguages(_ dtos: [LanguageDTO], version: String) throws {
        for dto in dtos {
            let entity = try upsert(LanguageEntity.self, id: dto.id) { LanguageEntity(id: dto.id) }
            entity.code = dto.code
            entity.label = dto.label
            entity.sort = dto.sort
            entity.isActive = dto.active
            entity.fetchedVersion = version
        }
        try prune(LanguageEntity.self, keeping: dtos.map(\.id))
        try modelContext.save()
    }

    func importPages(
        _ dtos: [PageDTO],
        translations: [PageTranslationDTO],
        version: String,
        isCompleteSet: Bool
    ) throws {
        let codes = try languageCodesByID()

        for dto in dtos {
            let entity = try upsert(PageEntity.self, id: dto.id) { PageEntity(id: dto.id) }
            entity.slug = dto.slug
            entity.icon = dto.icon
            entity.sort = dto.sort
            entity.fetchedVersion = version
        }
        if isCompleteSet {
            try prune(PageEntity.self, keeping: dtos.map(\.id))
        }

        for dto in translations {
            guard let code = codes[dto.languageID] else { continue }
            let entity = try upsert(PageTranslationEntity.self, id: dto.id) {
                PageTranslationEntity(id: dto.id)
            }
            entity.languageCode = code
            entity.title = dto.title
            entity.body = dto.body
            entity.fetchedVersion = version
            entity.page = try find(PageEntity.self, id: dto.pageID)
            dropSuperseded(entity, among: entity.page?.translations ?? [])
        }

        if isCompleteSet {
            try pruneTranslations(of: dtos, keeping: translations.map(\.id))
        }
        try modelContext.save()
    }

    func importMap(floors: [FloorDTO], rooms: [RoomDTO], version: String) throws {
        for dto in floors {
            let entity = try upsert(FloorEntity.self, id: dto.id) { FloorEntity(id: dto.id) }
            entity.name = dto.name
            entity.level = dto.level
            entity.mapPath = dto.mapPath ?? ""
            entity.sort = dto.sort
            entity.fetchedVersion = version
        }
        try prune(FloorEntity.self, keeping: floors.map(\.id))

        for dto in rooms {
            let entity = try upsert(RoomEntity.self, id: dto.id) { RoomEntity(id: dto.id) }
            entity.floorID = dto.floorID
            entity.name = dto.name
            entity.code = dto.code
            entity.sort = dto.sort
            entity.fetchedVersion = version
        }
        try prune(RoomEntity.self, keeping: rooms.map(\.id))
        try modelContext.save()
    }

    func importExhibitions(
        _ dtos: [ExhibitionDTO],
        translations: [ExhibitionTranslationDTO],
        version: String,
        isCompleteSet: Bool
    ) throws {
        let codes = try languageCodesByID()

        for dto in dtos {
            let entity = try upsert(ExhibitionEntity.self, id: dto.id) {
                ExhibitionEntity(id: dto.id)
            }
            entity.slug = dto.slug
            entity.coverPath = dto.coverPath ?? ""
            entity.isPermanent = dto.isPermanent
            entity.startDate = dto.startDate
            entity.endDate = dto.endDate
            entity.roomIDs = dto.roomIDs
            entity.sort = dto.sort
            entity.fetchedVersion = version
        }
        if isCompleteSet {
            try prune(ExhibitionEntity.self, keeping: dtos.map(\.id))
        }

        for dto in translations {
            guard let code = codes[dto.languageID] else { continue }
            let entity = try upsert(ExhibitionTranslationEntity.self, id: dto.id) {
                ExhibitionTranslationEntity(id: dto.id)
            }
            entity.languageCode = code
            entity.title = dto.title
            entity.subtitle = dto.subtitle
            entity.summary = dto.description
            entity.audioPath = dto.audioPath ?? ""
            entity.fetchedVersion = version
            entity.exhibition = try find(ExhibitionEntity.self, id: dto.exhibitionID)
            dropSuperseded(entity, among: entity.exhibition?.translations ?? [])
        }

        if isCompleteSet {
            try pruneTranslations(of: dtos, keeping: translations.map(\.id))
        }
        try modelContext.save()
    }

    func importArtworks(
        _ dtos: [ArtworkDTO],
        translations: [ArtworkTranslationDTO],
        version: String,
        includesFullText: Bool,
        isCompleteSet: Bool
    ) throws {
        let codes = try languageCodesByID()

        for dto in dtos {
            let entity = try upsert(ArtworkEntity.self, id: dto.id) { ArtworkEntity(id: dto.id) }
            entity.exhibitionID = dto.exhibitionID
            entity.roomID = dto.roomID
            entity.posX = dto.posX
            entity.posY = dto.posY
            entity.code = dto.code
            entity.artist = dto.artist
            entity.year = dto.year
            entity.technique = dto.technique
            entity.inventoryNumber = dto.inventoryNumber
            entity.imagePaths = dto.imagePaths
            entity.sort = dto.sort
            entity.fetchedVersion = version
            if includesFullText {
                entity.fullTextVersion = version
            }
        }

        for dto in translations {
            guard let code = codes[dto.languageID] else { continue }
            let entity = try upsert(ArtworkTranslationEntity.self, id: dto.id) {
                ArtworkTranslationEntity(id: dto.id)
            }
            entity.languageCode = code
            entity.title = dto.title
            if includesFullText {
                entity.text = dto.text
            }
            entity.audioPath = dto.audioPath ?? ""
            entity.audioDuration = dto.audioDuration
            entity.fetchedVersion = version
            entity.artwork = try find(ArtworkEntity.self, id: dto.artworkID)
            dropSuperseded(entity, among: entity.artwork?.translations ?? [])
        }

        if isCompleteSet {
            try pruneTranslations(of: dtos, keeping: translations.map(\.id))
        }
        try modelContext.save()
    }

    private func pruneTranslations(of artworks: [ArtworkDTO], keeping ids: [String]) throws {
        let kept = Set(ids)
        for dto in artworks {
            guard let artwork = try find(ArtworkEntity.self, id: dto.id) else { continue }
            for translation in artwork.translations where !kept.contains(translation.id) {
                modelContext.delete(translation)
            }
        }
    }

    private func pruneTranslations(of exhibitions: [ExhibitionDTO], keeping ids: [String]) throws {
        let kept = Set(ids)
        for dto in exhibitions {
            guard let exhibition = try find(ExhibitionEntity.self, id: dto.id) else { continue }
            for translation in exhibition.translations where !kept.contains(translation.id) {
                modelContext.delete(translation)
            }
        }
    }

    private func pruneTranslations(of pages: [PageDTO], keeping ids: [String]) throws {
        let kept = Set(ids)
        for dto in pages {
            guard let page = try find(PageEntity.self, id: dto.id) else { continue }
            for translation in page.translations where !kept.contains(translation.id) {
                modelContext.delete(translation)
            }
        }
    }

    private func dropSuperseded<Translation: PersistentModel & LocalizedTranslation>(
        _ entity: Translation,
        among siblings: [Translation]
    ) {
        for sibling in siblings
        where sibling.serverID != entity.serverID && sibling.languageCode == entity.languageCode {
            modelContext.delete(sibling)
        }
    }

    func pruneArtworks(exhibitionID: String, keeping ids: [String]) throws {
        let kept = Set(ids)
        let descriptor = FetchDescriptor<ArtworkEntity>(
            predicate: #Predicate { $0.exhibitionID == exhibitionID }
        )
        for entity in try modelContext.fetch(descriptor) where !kept.contains(entity.id) {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }

    func deleteArtwork(id: String) throws {
        guard let entity = try find(ArtworkEntity.self, id: id) else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }

    func updateSyncState(version: String, checkedAt: Date) throws {
        let state = try syncState()
        state.contentVersion = version
        state.lastCheckedAt = checkedAt
        try modelContext.save()
    }

    func updateSelectedLanguage(_ code: String) throws {
        let state = try syncState()
        state.selectedLanguageCode = code
        try modelContext.save()
    }

    func purgeAll() throws {
        try modelContext.delete(model: ArtworkTranslationEntity.self)
        try modelContext.delete(model: ArtworkEntity.self)
        try modelContext.delete(model: ExhibitionTranslationEntity.self)
        try modelContext.delete(model: ExhibitionEntity.self)
        try modelContext.delete(model: PageTranslationEntity.self)
        try modelContext.delete(model: PageEntity.self)
        try modelContext.delete(model: RoomEntity.self)
        try modelContext.delete(model: FloorEntity.self)
        try modelContext.delete(model: LanguageEntity.self)
        try modelContext.delete(model: MuseumEntity.self)
        try modelContext.delete(model: MediaAssetEntity.self)

        let state = try syncState()
        state.contentVersion = ""
        state.lastCheckedAt = nil
        try modelContext.save()
    }

    private func syncState() throws -> SyncStateEntity {
        try upsert(SyncStateEntity.self, id: SyncStateEntity.singletonID) {
            SyncStateEntity()
        }
    }

    private func languageCodesByID() throws -> [String: String] {
        let languages = try modelContext.fetch(FetchDescriptor<LanguageEntity>())
        return Dictionary(
            languages.map { ($0.id, $0.code) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private func find<Entity: PersistentModel & IdentifiableByServerID>(
        _ type: Entity.Type,
        id: String
    ) throws -> Entity? {
        guard !id.isEmpty else { return nil }
        var descriptor = FetchDescriptor<Entity>(predicate: Entity.predicate(id: id))
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func upsert<Entity: PersistentModel & IdentifiableByServerID>(
        _ type: Entity.Type,
        id: String,
        make: () -> Entity
    ) throws -> Entity {
        if let existing = try find(type, id: id) { return existing }
        let created = make()
        modelContext.insert(created)
        return created
    }

    private func prune<Entity: PersistentModel & IdentifiableByServerID>(
        _ type: Entity.Type,
        keeping ids: [String]
    ) throws {
        let kept = Set(ids)
        for entity in try modelContext.fetch(FetchDescriptor<Entity>())
        where !kept.contains(entity.serverID) {
            modelContext.delete(entity)
        }
    }
}

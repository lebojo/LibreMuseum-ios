import Foundation
import UIKit

@MainActor
enum EntityToUI {
    static func languageContext(
        museum: MuseumEntity?,
        languages: [LanguageEntity],
        selectedCode: String
    ) -> LanguageContext {
        let museumDefault = languages.first { $0.id == museum?.defaultLanguageID }?.code ?? ""
        let display = LanguageResolver.displayCode(
            selected: selectedCode,
            availableCodes: languages.map(\.code),
            museumDefault: museumDefault
        ) ?? ""
        return LanguageContext(displayCode: display, museumDefaultCode: museumDefault)
    }

    static func museum(_ entity: MuseumEntity) -> MuseumUI {
        MuseumUI(
            id: entity.id,
            name: entity.name,
            subtitle: entity.subtitle,
            logoPath: entity.logoPath,
            coverPath: entity.coverPath
        )
    }

    static func museumContact(_ entity: MuseumEntity) -> MuseumContactUI {
        MuseumContactUI(
            website: entity.website,
            email: entity.email,
            phone: entity.phone,
            address: entity.address,
            latitude: entity.latitude,
            longitude: entity.longitude
        )
    }

    static func exhibition(_ entity: ExhibitionEntity, in context: LanguageContext) -> ExhibitionUI {
        let translation = LanguageResolver.pick(
            from: entity.translations,
            in: context,
            languageCode: \.languageCode
        )
        let displayTitle = translation?.title.nilIfEmpty ?? entity.slug

        return ExhibitionUI(
            id: entity.id,
            title: displayTitle,
            searchableTitles: searchIndex(displayTitle, entity.translations.map(\.title)),
            subtitle: translation?.subtitle ?? "",
            coverPath: entity.coverPath,
            isPermanent: entity.isPermanent,
            startDate: entity.startDate,
            endDate: entity.endDate,
            dateRange: dateRange(start: entity.startDate, end: entity.endDate,
                                 isPermanent: entity.isPermanent),
            hasTranslation: translation != nil
        )
    }

    static func exhibitionDetail(
        _ entity: ExhibitionEntity,
        in context: LanguageContext
    ) -> ExhibitionDetailUI {
        let translation = LanguageResolver.pick(
            from: entity.translations,
            in: context,
            languageCode: \.languageCode
        )

        return ExhibitionDetailUI(
            id: entity.id,
            title: translation?.title.nilIfEmpty ?? entity.slug,
            subtitle: translation?.subtitle ?? "",
            summary: translation?.summary ?? "",
            coverPath: entity.coverPath,
            isPermanent: entity.isPermanent,
            dateRange: dateRange(start: entity.startDate, end: entity.endDate,
                                 isPermanent: entity.isPermanent),
            audioPath: translation?.audioPath ?? "",
            hasTranslation: translation != nil
        )
    }

    static func artwork(_ entity: ArtworkEntity, in context: LanguageContext) -> ArtworkUI {
        let translation = LanguageResolver.pick(
            from: entity.translations,
            in: context,
            languageCode: \.languageCode
        )
        let displayTitle = title(of: entity, translated: translation?.title)

        return ArtworkUI(
            id: entity.id,
            code: entity.code,
            title: displayTitle,
            searchableTitles: searchIndex(displayTitle, entity.translations.map(\.title)),
            artist: entity.artist,
            year: entity.year,
            thumbnailPath: entity.imagePaths.first ?? "",
            hasAudioGuide: !(translation?.audioPath ?? "").isEmpty
        )
    }

    static func artworkDetail(
        _ entity: ArtworkEntity,
        rooms: [RoomEntity],
        in context: LanguageContext
    ) -> ArtworkDetailUI {
        let translation = LanguageResolver.pick(
            from: entity.translations,
            in: context,
            languageCode: \.languageCode
        )

        return ArtworkDetailUI(
            id: entity.id,
            code: entity.code,
            title: title(of: entity, translated: translation?.title),
            artist: entity.artist,
            year: entity.year,
            technique: entity.technique,
            inventoryNumber: entity.inventoryNumber,
            roomName: rooms.first { $0.id == entity.roomID }?.name ?? "",
            imagePaths: entity.imagePaths,
            text: translation?.text ?? "",
            audioPath: translation?.audioPath ?? "",
            audioDuration: translation?.audioDuration ?? 0,
            textLanguageCode: translation?.languageCode ?? "",
            hasTranslation: translation != nil
        )
    }

    static func mapPin(
        _ entity: ArtworkEntity,
        exhibition: ExhibitionEntity?,
        in context: LanguageContext
    ) -> MapPinUI? {
        guard entity.hasMapPosition else { return nil }
        let translation = LanguageResolver.pick(
            from: entity.translations,
            in: context,
            languageCode: \.languageCode
        )
        let exhibitionTranslation = LanguageResolver.pick(
            from: exhibition?.translations ?? [],
            in: context,
            languageCode: \.languageCode
        )

        return MapPinUI(
            id: entity.id,
            label: entity.code,
            title: title(of: entity, translated: translation?.title),
            exhibitionTitle: exhibitionTranslation?.title.nilIfEmpty ?? exhibition?.slug ?? "",
            colorHex: exhibition?.colorHex ?? "",
            relativeX: min(max(entity.posX, 0), 1),
            relativeY: min(max(entity.posY, 0), 1)
        )
    }

    static func floor(_ entity: FloorEntity) -> FloorUI {
        FloorUI(id: entity.id, name: entity.name, level: entity.level, mapPath: entity.mapPath)
    }

    static func room(_ entity: RoomEntity) -> RoomUI {
        RoomUI(id: entity.id, name: entity.name, code: entity.code)
    }

    static func language(_ entity: LanguageEntity) -> LanguageUI {
        LanguageUI(id: entity.id, code: entity.code, label: entity.label)
    }

    static func page(_ entity: PageEntity, in context: LanguageContext) -> PageUI {
        let translation = LanguageResolver.pick(
            from: entity.translations,
            in: context,
            languageCode: \.languageCode
        )
        return PageUI(
            id: entity.id,
            title: translation?.title.nilIfEmpty ?? entity.slug,
            symbolName: existingSymbolName(entity.icon)
        )
    }

    static func pageDetail(_ entity: PageEntity, in context: LanguageContext) -> PageDetailUI {
        let translation = LanguageResolver.pick(
            from: entity.translations,
            in: context,
            languageCode: \.languageCode
        )
        return PageDetailUI(
            id: entity.id,
            title: translation?.title.nilIfEmpty ?? entity.slug,
            body: translation?.body ?? ""
        )
    }

    private static func searchIndex(_ displayTitle: String, _ translated: [String]) -> [String] {
        var seen: Set<String> = []
        return ([displayTitle] + translated).filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    private static func title(of entity: ArtworkEntity, translated: String?) -> String {
        translated?.nilIfEmpty
            ?? entity.inventoryNumber.nilIfEmpty
            ?? String(localized: "Untitled")
    }

    private static func dateRange(start: Date?, end: Date?, isPermanent: Bool) -> String? {
        guard !isPermanent else { return nil }
        let style = Date.FormatStyle(date: .abbreviated, time: .omitted)

        switch (start, end) {
        case let (start?, end?):
            return "\(start.formatted(style)) – \(end.formatted(style))"
        case let (start?, nil):
            return String(localized: "From \(start.formatted(style))")
        case let (nil, end?):
            return String(localized: "Until \(end.formatted(style))")
        case (nil, nil):
            return nil
        }
    }

    private static func existingSymbolName(_ name: String, fallback: String = "doc.text") -> String {
        guard !name.isEmpty, UIImage(systemName: name) != nil else { return fallback }
        return name
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

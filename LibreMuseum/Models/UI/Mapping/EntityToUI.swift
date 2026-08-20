import Foundation
import UIKit

@MainActor
enum EntityToUI {
    static func museum(_ entity: MuseumEntity) -> MuseumUI {
        MuseumUI(
            id: entity.id,
            name: entity.name,
            subtitle: entity.subtitle,
            logoPath: entity.logoPath,
            coverPath: entity.coverPath
        )
    }

    static func exhibition(
        _ entity: ExhibitionEntity,
        languageCode: String,
        museumDefault: String
    ) -> ExhibitionUI {
        let translation = LanguageResolver.pick(
            from: entity.translations,
            code: languageCode,
            museumDefault: museumDefault,
            languageCode: \.languageCode
        )

        return ExhibitionUI(
            id: entity.id,

            title: translation?.title.nilIfEmpty ?? entity.slug,
            subtitle: translation?.subtitle ?? "",
            coverPath: entity.coverPath,
            isPermanent: entity.isPermanent,
            dateRange: dateRange(start: entity.startDate, end: entity.endDate,
                                 isPermanent: entity.isPermanent),
            hasTranslation: translation != nil
        )
    }

    static func language(_ entity: LanguageEntity) -> LanguageUI {
        LanguageUI(id: entity.id, code: entity.code, label: entity.label)
    }

    static func page(
        _ entity: PageEntity,
        languageCode: String,
        museumDefault: String
    ) -> PageUI {
        let translation = LanguageResolver.pick(
            from: entity.translations,
            code: languageCode,
            museumDefault: museumDefault,
            languageCode: \.languageCode
        )
        return PageUI(
            id: entity.id,
            title: translation?.title.nilIfEmpty ?? entity.slug,
            symbolName: existingSymbolName(entity.icon)
        )
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

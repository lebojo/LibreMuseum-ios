import Foundation

nonisolated enum LanguageResolver {
    static func displayCode(
        selected: String,
        availableCodes: [String],
        museumDefault: String,
        deviceLanguages: [String] = Locale.preferredLanguages
    ) -> String? {
        guard !availableCodes.isEmpty else { return nil }

        if !selected.isEmpty, availableCodes.contains(selected) {
            return selected
        }
        if let matched = deviceMatch(availableCodes: availableCodes, deviceLanguages: deviceLanguages) {
            return matched
        }
        if !museumDefault.isEmpty, availableCodes.contains(museumDefault) {
            return museumDefault
        }
        return availableCodes.first
    }

    private static func deviceMatch(
        availableCodes: [String],
        deviceLanguages: [String]
    ) -> String? {
        for identifier in deviceLanguages {
            let locale = Locale(identifier: identifier)

            if let exact = availableCodes.first(where: {
                $0.caseInsensitiveCompare(identifier) == .orderedSame
            }) {
                return exact
            }
            guard let language = locale.language.languageCode?.identifier else { continue }
            if let base = availableCodes.first(where: {
                Locale(identifier: $0).language.languageCode?.identifier == language
            }) {
                return base
            }
        }
        return nil
    }

    static func pick<Translation>(
        from translations: [Translation],
        code: String,
        museumDefault: String,
        languageCode: (Translation) -> String
    ) -> Translation? {
        if let match = translations.first(where: { languageCode($0) == code }) {
            return match
        }
        if !museumDefault.isEmpty,
           let fallback = translations.first(where: { languageCode($0) == museumDefault }) {
            return fallback
        }
        return translations.first
    }
}

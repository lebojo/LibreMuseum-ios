import SwiftUI
import UIKit

struct HTMLTextView: View {
    @State private var attributed: AttributedString?

    let html: String
    var font: Font = .museumBody

    var body: some View {
        Group {
            if let attributed {
                Text(attributed)
            } else {
                Text(html.strippingHTMLTags).font(font)
            }
        }
        .task(id: html) { attributed = Self.attributedString(fromHTML: html, baseFont: font) }
    }

    @MainActor
    private static func attributedString(fromHTML html: String, baseFont: Font) -> AttributedString? {
        guard !html.isEmpty, let data = html.data(using: .utf8) else { return nil }
        guard let ns = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil
        ) else { return nil }

        var result = AttributedString(ns)

        let importedFonts = result.runs.map {
            ($0.range, $0[AttributeScopes.UIKitAttributes.FontAttribute.self])
        }
        for (range, importedFont) in importedFonts {
            result[range].font = baseFont.matching(importedFont)
        }

        result[AttributeScopes.UIKitAttributes.FontAttribute.self] = nil
        result[AttributeScopes.UIKitAttributes.ForegroundColorAttribute.self] = nil
        result[AttributeScopes.UIKitAttributes.BackgroundColorAttribute.self] = nil
        result.foregroundColor = nil
        result.backgroundColor = nil
        return result
    }
}

extension Font {
    func matching(_ importedFont: UIFont?) -> Font {
        let traits = importedFont?.fontDescriptor.symbolicTraits ?? []
        var font = self
        if traits.contains(.traitBold) { font = font.bold() }
        if traits.contains(.traitItalic) { font = font.italic() }
        return font
    }
}

extension String {
    var strippingHTMLTags: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

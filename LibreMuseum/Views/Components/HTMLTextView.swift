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
            .decodingNumericHTMLEntities
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var decodingNumericHTMLEntities: String {
        guard contains("&#"),
              let matcher = try? NSRegularExpression(
                  pattern: "&#(x[0-9a-f]+|[0-9]+);",
                  options: .caseInsensitive
              )
        else { return self }

        var decoded = ""
        var cursor = startIndex
        for match in matcher.matches(in: self, range: NSRange(startIndex..., in: self)) {
            guard let entity = Range(match.range, in: self),
                  let digits = Range(match.range(at: 1), in: self),
                  let character = Self.character(fromHTMLCodePoint: self[digits])
            else { continue }

            decoded += self[cursor..<entity.lowerBound]
            decoded.append(character)
            cursor = entity.upperBound
        }
        return decoded + self[cursor...]
    }

    private static func character(fromHTMLCodePoint digits: Substring) -> Character? {
        let hexadecimal = digits.first == "x" || digits.first == "X"
        let value = hexadecimal
            ? UInt32(digits.dropFirst(), radix: 16)
            : UInt32(digits, radix: 10)

        guard let value, let scalar = Unicode.Scalar(value) else { return nil }
        return Character(scalar)
    }

    var strippingHTMLTagsKeepingLineBreaks: String {
        replacingOccurrences(
            of: "</(p|div|li|h[1-6]|blockquote|tr)>|<br[^>]*>",
            with: "\n",
            options: [.regularExpression, .caseInsensitive]
        )
        .strippingHTMLTags
    }
}

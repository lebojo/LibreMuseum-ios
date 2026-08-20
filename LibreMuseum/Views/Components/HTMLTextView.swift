import SwiftUI

struct HTMLTextView: View {
    @State private var attributed: AttributedString?

    let html: String
    var font: Font = .museumBody

    var body: some View {
        Group {
            if let attributed {
                Text(attributed)
            } else {
                Text(html.strippingHTMLTags)
            }
        }
        .font(font)
        .task(id: html) { attributed = Self.attributedString(fromHTML: html) }
    }

    @MainActor
    private static func attributedString(fromHTML html: String) -> AttributedString? {
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

        result.font = nil
        result.foregroundColor = nil
        return result
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

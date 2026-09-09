import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct ZoomableFloorPlanView: UIViewRepresentable {
    final class Coordinator {
        var loadedPath = ""
    }

    let data: Data
    let path: String
    let accessibilityLabel: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bouncesZoom = true
        webView.scrollView.decelerationRate = .fast
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.allowsLinkPreview = false
        webView.isAccessibilityElement = true
        webView.accessibilityTraits = .image
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.accessibilityLabel = accessibilityLabel
        guard context.coordinator.loadedPath != path else { return }
        context.coordinator.loadedPath = path
        webView.loadHTMLString(html, baseURL: nil)
    }

    private var mimeType: String {
        let pathExtension = URL(fileURLWithPath: path).pathExtension
        return UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }

    private var html: String {
        let encodedData = data.base64EncodedString()
        return """
        <!doctype html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=8, user-scalable=yes">
        <style>
        html, body { width: 100%; height: 100%; margin: 0; overflow: auto; background: transparent; }
        body { display: flex; align-items: center; justify-content: center; }
        img { width: 100%; height: 100%; object-fit: contain; -webkit-user-select: none; -webkit-touch-callout: none; }
        </style>
        </head>
        <body><img src="data:\(mimeType);base64,\(encodedData)"></body>
        </html>
        """
    }
}

import SwiftUI
import WebKit

/// Renders a bundled HTML file in a transparent WKWebView — used for onboarding
/// animations built as self-contained HTML/Canvas. Scroll/bounce disabled so it
/// sits inline like an image, not like a web page.
struct HTMLAnimationView: UIViewRepresentable {
    let resourceName: String
    let resourceExtension: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        let parchment = UIColor(red: 0xF5/255.0, green: 0xED/255.0, blue: 0xD6/255.0, alpha: 1.0)
        webView.isOpaque = false
        webView.backgroundColor = parchment
        webView.scrollView.backgroundColor = parchment
        webView.scrollView.isOpaque = false
        if #available(iOS 15.0, *) {
            webView.underPageBackgroundColor = parchment
        }
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension)
        else { return }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}

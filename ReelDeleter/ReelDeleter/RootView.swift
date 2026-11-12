import SwiftUI
import WebKit

struct RootView: View {
    @EnvironmentObject private var store: WebStore

    var body: some View {
        InstagramWebView(webView: store.webView)
            // Matches Instagram's own background in light and dark mode, so the strips
            // above and below the page (status bar, home indicator) don't show a seam.
            .background(Color(.systemBackground).ignoresSafeArea())
            .sheet(isPresented: $store.showSettings, onDismiss: { store.settingsClosed() }) {
                SettingsView()
            }
    }
}

/// Hands SwiftUI the web view that WebStore already created and started loading.
private struct InstagramWebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

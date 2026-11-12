import SwiftUI
import WebKit

/// Owns the one long-lived web view. It is created at app launch and starts loading
/// Instagram straight away, before any SwiftUI view exists, which is the main latency win.
@MainActor
final class WebStore: NSObject, ObservableObject {
    static let shared = WebStore()
    static let home = URL(string: "https://www.instagram.com/")!

    // A Safari-looking user agent, so Instagram serves its normal mobile site instead of
    // treating this as an embedded browser. Edit the version numbers if Instagram misbehaves.
    private static let safariUA =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1"

    // Hosts that stay inside the app. Tapped links to anything else open in Safari.
    private static let internalHosts = [
        "instagram.com", "facebook.com", "fbcdn.net", "cdninstagram.com", "facebook.net", "meta.com",
    ]

    let webView: WKWebView
    @Published var showSettings = false
    private let settings = FilterSettings.shared

    private override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()          // persistent, so you stay logged in
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.addUserScript(FilterSettings.shared.makeUserScript())

        webView = WKWebView(frame: .zero, configuration: config)
        super.init()

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground
        if settings.safariUserAgent { webView.customUserAgent = Self.safariUA }
        // Lets you debug the page from Safari on a Mac: Develop > [your iPhone] > Reel Deleter.
        if #available(iOS 16.4, *) { webView.isInspectable = true }

        // Two-finger long press anywhere opens the settings sheet.
        let press = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        press.numberOfTouchesRequired = 2
        press.minimumPressDuration = 0.8
        press.cancelsTouchesInView = false
        press.delegate = self
        webView.addGestureRecognizer(press)

        webView.load(URLRequest(url: Self.home))
    }

    @objc private func longPressed(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { showSettings = true }
    }

    // MARK: Settings

    /// Called when the settings sheet closes. Reloads only if something changed.
    func settingsClosed() {
        guard settings.needsReload else { return }
        settings.needsReload = false
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()
        controller.addUserScript(settings.makeUserScript())
        webView.customUserAgent = settings.safariUserAgent ? Self.safariUA : nil
        webView.reload()
    }

    func clearData() {
        Task {
            let store = WKWebsiteDataStore.default()
            let types = WKWebsiteDataStore.allWebsiteDataTypes()
            let records = await store.dataRecords(ofTypes: types)
            await store.removeData(ofTypes: types, for: records)
            webView.load(URLRequest(url: Self.home))
        }
    }

    // MARK: Page report (debugging without a Mac)

    /// Copies a short, text-only description of the page behind the settings sheet (nav links,
    /// which of them were hidden, a few labels) so it can be pasted into a chat when something
    /// isn't being hidden. Safari's Web Inspector would need a Mac.
    func copyPageReport(completion: @escaping (Bool) -> Void) {
        webView.evaluateJavaScript(Self.reportScript) { value, _ in
            if let text = value as? String {
                UIPasteboard.general.string = text
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    private static let reportScript = #"""
    (() => {
      const rect = (el) => { const r = el.getBoundingClientRect(); return [Math.round(r.x), Math.round(r.y), Math.round(r.width), Math.round(r.height)]; };
      const describe = (a) => ({
        href: a.getAttribute('href'),
        label: (a.getAttribute('aria-label') || a.textContent || '').trim().slice(0, 40),
        hidden: !!a.closest('[data-rd-hidden]'),
        rect: rect(a),
      });
      const links = Array.from(document.querySelectorAll('a[href]')).slice(0, 600).map(describe);
      const nearEdge = (l) => l.rect[2] > 0 && (l.rect[1] < 110 || l.rect[1] > innerHeight - 150);
      const labels = Array.from(new Set(
        Array.from(document.querySelectorAll('[aria-label]')).map((e) => e.getAttribute('aria-label')))).slice(0, 60);
      return JSON.stringify({
        url: location.href,
        userAgent: navigator.userAgent,
        viewport: [innerWidth, innerHeight],
        filterStyleInjected: !!document.getElementById('rd-style'),
        hiddenElements: document.querySelectorAll('[data-rd-hidden]').length,
        reelsOrExploreLinks: links.filter((l) => /reel|explore/.test(l.href)),
        linksNearTopOrBottom: links.filter(nearEdge).slice(0, 40),
        ariaLabels: labels,
      }, null, 1);
    })()
    """#

    // MARK: reeldeleter:// links (used by the Shortcuts automation)

    /// reeldeleter://home      the feed
    /// reeldeleter://inbox     messages
    /// reeldeleter://settings  this app's settings
    /// reeldeleter://open?path=/some/path/
    func handle(url: URL) {
        guard url.scheme == "reeldeleter" else { return }
        switch url.host {
        case "home": navigate(toPath: "/")
        case "inbox": navigate(toPath: "/direct/inbox/")
        case "settings": showSettings = true
        case "open":
            let path = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "path" })?.value
            if let path { navigate(toPath: path) }
        default: break
        }
    }

    /// Goes to a path on instagram.com. Clicks Instagram's own link when it is on screen,
    /// which is instant because the page doesn't reload; otherwise loads the URL.
    private func navigate(toPath path: String) {
        guard path.hasPrefix("/"), !path.hasPrefix("//"),
              let url = URL(string: path, relativeTo: Self.home)?.absoluteURL else { return }
        let literal = (try? JSONEncoder().encode(path)).flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""
        let js = """
        (() => {
          const path = \(literal);
          const a = Array.from(document.querySelectorAll('a[href]')).find(x => x.getAttribute('href') === path);
          if (a) { a.click(); return true; }
          return false;
        })()
        """
        webView.evaluateJavaScript(js) { [weak self] value, _ in
            if (value as? Bool) == true { return }
            self?.webView.load(URLRequest(url: url))
        }
    }

    // MARK: Links that should leave the app

    /// Returns where a link should open outside the app, or nil to keep it in the web view.
    private func externalTarget(for url: URL) -> URL? {
        guard let scheme = url.scheme?.lowercased() else { return nil }
        if ["mailto", "tel", "sms", "itms-apps"].contains(scheme) { return url }
        guard scheme == "http" || scheme == "https", let host = url.host?.lowercased() else { return nil }
        // Instagram wraps outbound links as l.instagram.com/?u=<real url>.
        if host == "l.instagram.com",
           let raw = URLComponents(url: url, resolvingAgainstBaseURL: false)?
               .queryItems?.first(where: { $0.name == "u" })?.value,
           let target = URL(string: raw) {
            return target
        }
        let isInternal = Self.internalHosts.contains { host == $0 || host.hasSuffix("." + $0) }
        return isInternal ? nil : url
    }

    private func openExternally(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension WebStore: WKNavigationDelegate, WKUIDelegate, UIGestureRecognizerDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           let external = externalTarget(for: url) {
            openExternally(external)
            return .cancel
        }
        return .allow
    }

    // target="_blank" links
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            if let external = externalTarget(for: url) {
                openExternally(external)
            } else {
                webView.load(navigationAction.request)
            }
        }
        return nil
    }

    // iOS can kill the web content process to free memory; this brings the page back.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}

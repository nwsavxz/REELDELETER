import Combine
import Foundation
import WebKit

/// Every option the app has, stored in UserDefaults.
final class FilterSettings: ObservableObject {
    static let shared = FilterSettings()

    /// Turns true whenever an option changes. WebStore reloads Instagram when the
    /// settings sheet closes, so the new script takes effect.
    var needsReload = false

    @Published var hideReelsTab: Bool { didSet { save(hideReelsTab, "hideReelsTab") } }
    @Published var blockReels: Bool { didSet { save(blockReels, "blockReels") } }
    @Published var allowDMReels: Bool { didSet { save(allowDMReels, "allowDMReels") } }
    @Published var hideExplore: Bool { didSet { save(hideExplore, "hideExplore") } }
    @Published var safariUserAgent: Bool { didSet { save(safariUserAgent, "safariUserAgent") } }
    @Published var customCSS: String { didSet { save(customCSS, "customCSS") } }

    private init() {
        let d = UserDefaults.standard
        d.register(defaults: [
            "hideReelsTab": true,
            "blockReels": true,
            "allowDMReels": true,
            "hideExplore": false,
            "safariUserAgent": true,
            "customCSS": "",
        ])
        hideReelsTab = d.bool(forKey: "hideReelsTab")
        blockReels = d.bool(forKey: "blockReels")
        allowDMReels = d.bool(forKey: "allowDMReels")
        hideExplore = d.bool(forKey: "hideExplore")
        safariUserAgent = d.bool(forKey: "safariUserAgent")
        customCSS = d.string(forKey: "customCSS") ?? ""
    }

    private func save(_ value: Any, _ key: String) {
        UserDefaults.standard.set(value, forKey: key)
        needsReload = true
    }

    /// The filter script with the current options baked in.
    func makeUserScript() -> WKUserScript {
        let config: [String: Any] = [
            "hideReelsTab": hideReelsTab,
            "blockReels": blockReels,
            "allowDMReels": allowDMReels,
            "hideExplore": hideExplore,
            "customCSS": customCSS,
            "debug": true,
        ]
        let json = (try? JSONSerialization.data(withJSONObject: config))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let source = "var RD_CONFIG = \(json);\n" + FilterScript.source
        return WKUserScript(
            source: source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true,
            in: .defaultClient
        )
    }
}

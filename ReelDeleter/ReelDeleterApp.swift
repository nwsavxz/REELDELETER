import SwiftUI

@main
struct ReelDeleterApp: App {
    init() {
        // Touching the store creates the web view and starts loading Instagram before
        // the first SwiftUI frame is drawn.
        _ = WebStore.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(WebStore.shared)
                .onOpenURL { WebStore.shared.handle(url: $0) }
        }
    }
}

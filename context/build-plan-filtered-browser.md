# Build plan: fast, native-feeling filtered Instagram browser (iPhone)

Written 12 Nov 2026. Direction chosen by the project owner: an iPhone app that loads and runs Instagram in a filtered in-app browser with minimum latency, lets the user customise what they see, and does not feel like Instagram in Safari.

## Verdict
Buildable; it is the same model as Dull and UNDOOMED. Speed and feel are achievable. Two things decide whether it ships: notifications and App Store review (guideline 4.2).

## 1. Latency
- Create the web view at app launch, before any UI, and start loading instagram.com immediately. One open-source warm-up library reported ~45% faster first load in its own test.
- One long-lived web view per tab (Home, Search, Messages, Profile), preloaded and swapped, so tab switches are instant. Cost: memory.
- Persistent website data store so the login survives launches.
- Show a snapshot of the last state while the live page wakes up (WKSnapshotConfiguration).
- Inject filtering at document start so nothing flashes before it is hidden.
- iOS 26+: SwiftUI WebView + WebPage; fall back to WKWebView for older iOS or legacy-only features.
- Measure time-to-interactive against Safari and the real app from day one.

## 2. Feels native
- No URL bar or Safari chrome; your own SwiftUI tab bar drives the web views.
- Native back-swipe gestures, pull-to-refresh, haptics, share sheet, safe areas, dark mode; disable text selection and link previews where they feel webby.
- Prefer CSS display:none over heavy JS in scroll paths.
- Whether or not Instagram's mobile web is deliberately clunky (not verified), treat it as the baseline to beat and test gaps against the native app (creation tools, some DM features).

## 3. Filtering engine
- Layer A, routes: block /reels, redirect home. decidePolicyFor does NOT fire for single-page-app navigations (history.pushState). Hook pushState/replaceState/popstate in an injected script and observe WKWebView.url.
- Layer B, CSS: toggles for Reels tab, Reels in feed, Explore, suggested posts, Stories. Use stable hooks (href patterns, aria labels), not generated class names. Enable isInspectable in debug and use Safari Web Inspector to find them.
- Layer C, network: content-rule-list blocking of Reels/clips requests (same JSON rule format as Safari content blockers).
- Ship selectors as remote JSON data, not downloaded JavaScript. Remote configuration is fine under guideline 2.5.2; downloading code that adds features is not.
- Settings worth offering: Messages Only mode, allow Reels sent in DMs but no scrolling past, schedules, daily limits.
- Run injected scripts in an isolated content world (.defaultClient) so they do not share scope with page scripts.

## 4. Hard problems
Notifications
- Web Push does not work in WKWebView (Apple DTS). Native push works only for your own events, and you cannot send Instagram's.
- Option A: keep the native Instagram app installed for notifications and use a Shortcuts "app opened" automation to redirect launches into your app (ScrollGuard and one sec both rely on Shortcuts; iOS 26 needed an App Intent to break the open-app loop; iOS 27 can install automations automatically).
- Option B: shield the native app with the Screen Time API. Shielding also blocks its notifications, so this conflicts with keeping alerts.
- Deep-linking from a notification into the right DM needs testing.

App Review
- 4.2 rejects "repackaged websites". Add native depth: filter settings UI, schedules, time limits and usage stats, Screen Time shield integration, Shortcuts/App Intents, widgets or Focus filters. No change guarantees approval.
- 4.3 (spam) is a risk in a crowded category; differentiate.
- Users type their Instagram password into your web view: isolate scripts, never log or read credentials, say so in the privacy policy.
- Check Meta's terms and branding rules (no Instagram logo or name in the app name/icon). Not legal advice.

## 5. Build order
1. Single web view, persistent login, own tab bar, route blocking.
2. Document-start CSS + remote selector JSON + toggles.
3. Warm-up, per-tab web views, snapshot; benchmark.
4. Messages Only mode, DM-Reels allowance, schedules/limits.
5. Shortcuts redirect from the native app.
6. Screen Time shield and limits (request the Family Controls entitlement early; developers report days to weeks).
7. TestFlight, then App Review with clear notes.

## Not verified
Instagram web's current behaviour in an embedded web view (login challenges, user-agent handling, feature gaps), exact selectors, and whether Instagram web sends web push.

## Sources
- https://developer.apple.com/forums/thread/760767
- https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados
- https://github.com/mozilla-mobile/firefox-ios/wiki/WKWebView-navigation-and-security-considerations
- https://ptkd.com/journal/rejection-guideline-2-5-2-dynamic-code
- https://www.mobiloud.com/blog/app-store-review-guidelines-webview-wrapper
- https://vp0.com/blogs/fix-app-store-rejection-4-2-minimum-functionality
- https://github.com/bernikowich/NSTViewWarmuper
- https://sarunw.com/posts/swiftui-native-webview/
- https://developer.apple.com/forums/thread/818841
- https://tutorials.one-sec.app/en/articles/10309122
- https://dev.to/eliguzz/building-an-open-source-one-sec-alternative-breaking-the-shortcuts-infinite-loop-thanks-to-ios-26-ka4
- https://scrollguard-landing-page.pages.dev/blog/how-to-block-instagram-reels-iphone
- https://newly.app/how-to/family-controls-entitlement

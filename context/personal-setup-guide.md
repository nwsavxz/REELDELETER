# Reel Deleter: personal build and setup (iPhone, Windows PC, no Mac)

Written 12 Nov 2026, revised the same day after the owner said they have no Mac and use Windows. Goes with `build-plan-filtered-browser.md`. The source files were delivered as `ReelDeleter.zip` in the chat (six Swift files, `project.yml`, a GitHub Actions workflow, a README); they are not stored in this project.

## Decisions this follows
- Notifications: keep native Instagram installed for alerts; a Shortcuts automation forwards its launch to this app.
- App Review: ignored for now. The app is for the owner's own phone only.
- No Mac: build on GitHub's cloud Macs, install from Windows with Sideloadly.

## What was built
A SwiftUI app with one long-lived `WKWebView` that is created at app launch and starts loading instagram.com before the first screen draws. A script injected at document start (isolated content world, main frame only) does three things:
1. CSS to hide Reels/Explore links as early as possible.
2. Hides the whole tab item, not only the link: climbs up to 5 levels while the parent holds no other links.
3. Blocks Reels: capture-phase click guard plus a route guard (DOM mutations, popstate, a 500 ms poll) that calls `history.back()`, or `location.replace('/')` on a cold load or if it would loop.

Matched on URL paths, not Instagram's class names: `/reels`, `/reel/<id>`, `/<user>/reels`, `/explore` (optional). Options: hide Reels tabs, block every Reels page, still allow a Reel opened from a DM, hide and block Explore, custom CSS, Safari-style user agent. Settings open with a two-finger long press or `reeldeleter://settings`. Outbound links open in Safari. `reeldeleter://home`, `://inbox`, `://open?path=/...` are supported. Settings > Advanced > Copy page report puts a text description of the screen on the clipboard (nav link paths, which were hidden, aria labels), because Safari's Web Inspector needs a Mac.

Simplification versus the build plan: one web view that uses Instagram's own mobile nav, rather than one web view per native tab. Per-tab web views need verified URLs and selectors for each tab, so they are a later step.

## The no-Mac route
- `project.yml` is an XcodeGen spec. The workflow runs `brew install xcodegen` and `xcodegen generate` to make the `.xcodeproj` that Xcode would normally make. It sets iOS 17, Swift 5 language mode, the `reeldeleter` URL scheme, camera/mic/photo permission texts, and a unique bundle identifier.
- `.github/workflows/build.yml` runs on `macos-26`, builds with `CODE_SIGNING_ALLOWED=NO`, zips the `.app` into `Payload/` as `ReelDeleter.ipa`, uploads it as an artifact, and on failure writes the compiler errors to the run summary.
- Cost: public repo is free with no minute limit; a private repo gets 2,000 free minutes a month and macOS minutes count 10x, about 200 macOS minutes.
- Install: Sideloadly on Windows signs the unsigned IPA with the owner's Apple ID. Needs iTunes and iCloud from Apple's site (not Microsoft Store versions). Developer Mode only appears in iPhone Settings after a sideloaded app is installed.
- Free Apple ID limits: 7-day expiry (reinstall with the same Apple ID and bundle ID), at most 3 sideloaded apps, 10 App IDs per 7 days. A paid account ($99/yr) lasts up to a year.
- Alternative: AltStore with AltServer on Windows refreshes apps automatically over Wi-Fi while the PC is on. AltStore is itself a sideloaded app, so I expect it uses one of the three free slots (not confirmed).

## Verification status
- Verified: the injected JavaScript, 27 checks in jsdom against a fake page I wrote (tab hiding, wrapper climbing, click blocking, SPA route bounce with a cooldown, cold-load redirect, DM exception, Explore option, custom CSS, loop guard). Three deliberately broken copies each failed the matching checks. The page-report script also passes 7 checks.
- Verified: all six Swift files parse with a Swift syntax parser (tree-sitter), which checks syntax only. The workflow file passes the GitHub workflow schema check and actionlint. `project.yml` parses as YAML.
- NOT verified: the Swift has never been compiled or type-checked, so the first cloud build may fail. `project.yml` has never been run through XcodeGen (no macOS here), so the generated project, Info.plist and scheme are unconfirmed. XcodeGen 2.45+ needs `path:` alongside `properties:` under `info:`; that is set.
- NOT verified: anything against real Instagram. The fake page's markup is a guess. Unknown: whether the mobile nav uses `<a href="/reels/">` links, what the logged-in page looks like in an embedded web view, whether Instagram challenges the login, whether the Safari-style user agent helps or hurts.
- NOT verified: whether the app keeps its login after a re-install; whether Shortcuts' Open URLs opens a custom `reeldeleter://` link without a prompt.

## Shortcuts automation
Shortcuts > Automation > + > Create Personal Automation > App > Instagram > Is Opened > action **Open App** > Reel Deleter. Then turn off **Ask Before Running** (shown as Run Immediately on iOS 17+).

Sources conflict on "Notify When Run": Matthew Cassinelli (iOS 17 betas) says it is not offered and a notification is always shown; SlashGear says it works on iOS 18 (Run Immediately, then toggle Notify When Run off). Fallback from a MacRumors forum reply: Settings > Screen Time > See All App & Website Activity > Notifications > Shortcuts > Allow Notifications off.

Expect: native Instagram flashes for a moment; you land on the app's last screen, not the specific message you were notified about; `reeldeleter://inbox` in an Open URLs action would always land in messages, including when Instagram is opened from its icon; links to Instagram from other apps end up on your feed, not the linked post (inferred, not tested).

## Related
`scinsta-deep-dive.md` covers the sideloaded modified-Instagram route. It actually removes the Reels tab inside native Instagram but needs a decrypted IPA and loses push notifications when sideloaded, so it was not chosen. Existing free Safari extensions (see `short-form-blocker-competitors.md`) are the no-build fallback, but they work in Safari, not in an app-like window.

## Sources
- GitHub Docs, Actions billing (macOS 10x multiplier; public repos free): https://docs.github.com/en/billing/concepts/product-billing/github-actions
- GitHub changelog, macos-26 runners generally available: https://github.blog/changelog/2026-02-26-macos-26-is-now-generally-available-for-github-hosted-runners/
- Sideloadly (Windows needs non-Store iTunes and iCloud; reinstall with same Apple ID): https://sideloadly.io and https://sideloadly.io/faq
- Apple, membership comparison (7-day profiles, 3 apps per device, 10 App IDs): https://developer.apple.com/support/compare-memberships
- AltStore FAQ, AltServer release notes: https://faq.altstore.io/release-notes/altserver
- Developer Mode appears after installing a development app: https://thetechgorilla.com/how-to-enable-developer-mode-on-iphone/
- XcodeGen `info:` needs `path:` with `properties:` (2.45+): https://techconcepts.org/blog/xcodegen-multi-platform-projects
- Unsigned IPA packaging (Payload folder zipped): https://dev.to/oivoodoo/build-unsigned-ios-ipa-to-install-via-sideloadly-236f
- Matthew Cassinelli, automations run immediately in iOS 17: https://matthewcassinelli.com/automations-run-immediately-shortcuts-notifications/
- SlashGear, Shortcuts notifications on iOS 18: https://www.slashgear.com/1654953/iphone-disable-shortcut-app-notifications
- MacRumors forum, silencing Shortcuts via Screen Time: https://forums.macrumors.com/threads/shortcuts-app-how-to-not-get-notification-when-personal-auto-running.2442802

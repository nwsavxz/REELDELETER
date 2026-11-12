# iPhone: existing ways to remove Reels / short-form video

Researched 12 Nov 2026. Core constraint: iOS does not let one app modify another app, so no App Store app can remove the Reels tab from the real Instagram app. Everything below is either a setting, a whole-app block, a delay, a web-only filter, a replacement browser, or a modified copy of Instagram.

## Summary
| # | Approach | Removes Reels tab in the real app? | Keeps DMs/Stories | Typical cost |
|---|---|---|---|---|
| 1 | Instagram / YouTube settings | No (YouTube can be set to 0 min Shorts) | Yes | Free |
| 2 | Screen Time and Screen Time API blockers (Opal, AppBlock) | No, whole app only | No | Free to $99.99/yr |
| 3 | Friction via Shortcuts automations (one sec) | No, delays opening | Yes | Free to $14.99/yr |
| 4 | Safari web extensions (Nope, Slowth, Shorty, MindShield) | No, websites only | Yes, in Safari | Free to $1.99 |
| 5 | Filtered in-app browser (Dull, UNDOOMED, StopScroll, SocialLite, FeedLite, minulo) | No, replaces the app | Yes | Free tier to $59.99 lifetime |
| 6 | Shortcuts redirect to a filtered web app (ScrollGuard) | No, redirects out of it | Yes | Freemium |
| 7 | Sideloaded modified Instagram (SCInsta / BHInsta tweaks) | Yes | Yes | Free, but outside the App Store and Meta's terms |

## Details
1. Settings: Instagram has no switch to turn Reels off or remove the tab. You can hide the Suggested Reels shelf, mark Not Interested, and use "Your Algorithm" (top right of the Reels tab) to steer topics. YouTube added a Shorts feed limit that can be set to zero.
2. Screen Time API (FamilyControls, ManagedSettings, DeviceActivity): shields whole apps; the system hides blocked apps and stops them launching. Cannot see or alter content inside an app. Shielding Instagram also suppresses its notifications (developer forum thread by SocialLite's developer). Needs Apple's Family Controls entitlement, which developers report takes days to weeks. A WWDC 2026 write-up says Apple still has not extended shields to web domains or in-app features. Opal switched from a local VPN to this API in late 2022.
3. one sec: uses Shortcuts "app opened" automations to trigger a breathing pause. iOS 27 can install the automations automatically. Does not filter content.
4. Safari extensions: hide elements or redirect /reels/ URLs on instagram.com and youtube.com inside Safari. Do not affect the apps. Nope and Slowth (GPL, open source) are free; MindShield is $1.99.
5. Filtered in-app browser: the app loads instagram.com in its own web view and strips Reels/Explore/suggested with CSS/JS injection (Dull, UNDOOMED). Usually paired with deleting the native app.
6. ScrollGuard: Safari extension + web app + a Shortcuts automation that sends you from the native Instagram app to the filtered web app.
7. SCInsta / BHInsta: tweaks injected into a decrypted Instagram IPA that is sideloaded. Options include hide Reels tab, disable scrolling Reels, no suggested Reels. Its own FAQ says distributing modified Instagram builds is a copyright violation, so users must build their own, and push notifications work out of the box only for jailbroken or TrollStore users.

## Takeaway for the project
Only approach 7 truly removes the tab from the real app, and it cannot ship on the App Store. Approaches 5 and 6 are the closest legal equivalent; approach 4 is the cheapest to build; approach 2 is the only one that can enforce a hard stop.

## Sources
- https://apps.apple.com/us/app/-/id6768192042 (Nope: native Safari Web Extension)
- https://github.com/skar404/slowth
- https://apps.apple.com/us/app/mindshield/id1660218371
- https://getdull.app/block-reels-iphone/
- https://scrollguard-landing-page.pages.dev/blog/how-to-block-instagram-reels-iphone (vendor)
- https://tutorials.one-sec.app/en/articles/10309122
- https://developer.apple.com/forums/thread/818841
- https://newly.app/how-to/family-controls-entitlement
- https://habitdoom.com/blog/wwdc-2026-screen-time-wishlist
- https://techcrunch.com/2022/09/15/opal-revamps-its-screen-time-app-to-help-anyone-not-just-parents-with-kids-focus-and-avoid-distractions
- https://github.com/SoCuul/SCInsta/wiki/FAQ
- https://www.lilachbullock.com/mute-reels-instagram-stop-appearing/
- https://www.etvbharat.com/en/technology/youtube-adds-shorts-feed-limit-feature-to-help-users-manage-screen-time-enn26041701277

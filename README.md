# Reel Deleter: personal build, from Windows

A full-screen Instagram web view for your own iPhone. It hides the Reels tab, bounces any Reels page, and lets you add your own CSS. Not for the App Store.

You have no Mac, so a Mac in the cloud (GitHub Actions) builds the app for you, and a Windows program (Sideloadly) installs it on your iPhone.

**Status: the Swift has never been compiled.** The first cloud build may fail with a compile error. That is expected; the build page lists the errors, and you paste them back to be fixed. The filter JavaScript was tested against a fake page, not real Instagram.

## What you need

- A free GitHub account.
- Your iPhone, a USB cable, and your Apple ID (a free one works).
- The native Instagram app stays installed and logged in. It is what delivers notifications.

## Part 1: build the app in the cloud

1. Make a free account at github.com, then **New repository**. Name it `reel-deleter`.
   - **Public** is free with no minute limit. Nothing secret is in this project.
   - **Private** also works, but macOS builds count ten times against your 2,000 free minutes a month, which is roughly 200 minutes of build time.
2. Unzip this download. Open the outer `ReelDeleter` folder, select everything inside it (`project.yml`, `README.md`, the `ReelDeleter` folder and the `.github` folder) and drag it onto the repository page's **uploading an existing file** link. Then **Commit changes**.
   - If the `.github` folder doesn't come across: **Add file > Create new file**, type `.github/workflows/build.yml` as the file name (typing the slashes creates the folders), paste in the contents of that file, and commit.
3. Open the **Actions** tab. A run called **Build unsigned IPA** starts by itself after the commit. If GitHub asks you to enable workflows, enable them. Wait for the green tick. Expect it to take several minutes.
4. Click the finished run, scroll to **Artifacts**, download **ReelDeleter-ipa**, and unzip it. Inside is `ReelDeleter.ipa`.
5. **If the run has a red cross:** click it. The **Summary** page shows a **Compiler errors** box. Copy that box into your chat. After a fix, upload the changed file (open it in the repository, click the pencil, paste, commit) and the build runs again.

## Part 2: install it on your iPhone from Windows

1. Install **iTunes** and **iCloud** from Apple's website, not the Microsoft Store. Sideloadly does not work with the Microsoft Store versions. Remove those first if you have them.
2. Install **Sideloadly** from sideloadly.io.
3. Plug in the iPhone, unlock it, tap **Trust**.
4. Open Sideloadly, drag in `ReelDeleter.ipa`, enter your Apple ID, click **Start**, enter your password and the 2-factor code if asked. Several guides suggest a spare Apple ID for sideloading, because these tools sign in with your Apple ID password. Your call.
5. On the iPhone: Settings > General > VPN & Device Management > your Apple ID > **Trust**.
6. **Developer Mode:** iPhone Settings > Privacy & Security > scroll to the bottom > Developer Mode > on, then restart. It only appears after a sideloaded app has been installed. If it isn't there: unplug and replug, restart the phone, and turn off any Focus mode (those fixed it for some people).
7. Open Reel Deleter and log in to Instagram inside it. Instagram may email you a "new login" notice.

### The 7-day limit

On a free Apple ID the app stops opening after 7 days. To renew, reconnect the iPhone, drag the same IPA into Sideloadly again with the same Apple ID, and click Start. Sideloadly has an automatic refresh option, but it needs Sideloadly running on your PC. A free account allows at most 3 sideloaded apps. A paid Apple Developer account ($99/year) makes the install last a year.

Whether your Instagram login survives a re-install is untested.

## Part 3: notifications via a Shortcuts redirect

The native Instagram app keeps sending notifications. Tapping one opens native Instagram, and this automation immediately forwards you to Reel Deleter.

1. Shortcuts app > **Automation** tab > **+** > **Create Personal Automation** > **App**.
2. Tap Choose, pick **Instagram**, make sure **Is Opened** is selected (not Is Closed), then Next.
3. Add the action **Open App** and choose **Reel Deleter**.
4. Next. Switch **Ask Before Running** off (on iOS 17 and later this appears as **Run Immediately**). Look for a **Notify When Run** switch and turn it off if you see it. Sources disagree on whether newer iOS versions still show that switch. If you don't see it and the "Running your automation" banner annoys you: Settings > Screen Time > See All App & Website Activity > Notifications > Shortcuts > Allow Notifications off.
5. Done.

What to expect:

- Native Instagram flashes on screen for a moment before Reel Deleter takes over.
- You land on whatever screen Reel Deleter was last on, not on the specific message you were notified about. Open the inbox yourself. If you would rather always land in messages, use **Open URLs** with `reeldeleter://inbox` instead of Open App. That also applies when you open Instagram from its icon. Whether Shortcuts opens a custom-scheme link silently or asks first is untested.
- Links to Instagram from other apps open native Instagram first, then get forwarded, so you end up on your feed rather than the linked post.
- Native Instagram's Reels tab is untouched. The automation just makes sure you rarely see it.

## Using the app

- **Settings**: two-finger long press anywhere. Or open `reeldeleter://settings`.
- **Settings changes** reload Instagram when you close the sheet.
- **Custom CSS** is added to every page. This is how you hide anything else (stories tray, suggested posts, and so on).
- **Link types**: `reeldeleter://home`, `reeldeleter://inbox`, `reeldeleter://open?path=/some/path/`.

## When something isn't hidden

Safari's Web Inspector needs a Mac, so the app has a replacement:

1. Open Reel Deleter on the screen you're looking at (the feed, a profile, a message thread).
2. Two-finger long press, then **Advanced > Copy page report**.
3. Paste it into your chat. It lists the link paths and labels near the top and bottom of the screen, and says which ones were hidden. It can include usernames, so skim it first.

## If something doesn't work

| Symptom | Likely cause |
|---|---|
| Build shows a red cross | A compile error. Paste the **Compiler errors** box from the run summary. |
| Sideloadly says the bundle identifier is taken | In `project.yml`, change the last part of `PRODUCT_BUNDLE_IDENTIFIER` to anything else, commit, rebuild. |
| Developer Mode isn't in Settings | See Part 2, step 6. |
| Reels tab still visible | Instagram's nav doesn't use `<a href="/reels/">` links. Send a page report. |
| Login loops or "something went wrong" | Turn off "Send a Safari-style user agent" in Settings, or the reverse. |
| Bottom bar overlaps the home indicator | Instagram doesn't pad for the iPhone's safe area. Tell me and I'll change the layout. |
| App won't open after a week | The 7-day free-account limit. Reinstall with Sideloadly. |

If you ever get a Mac: install XcodeGen, run `xcodegen generate` in this folder, and open the `.xcodeproj` in Xcode.

## Files

| File | What it does |
|---|---|
| `.github/workflows/build.yml` | The cloud build: generates the Xcode project, builds without signing, packages the IPA |
| `project.yml` | Describes the Xcode project (name, iOS 17, the `reeldeleter://` link scheme, permission texts) |
| `ReelDeleter/ReelDeleterApp.swift` | Starts the web view before the first screen is drawn |
| `ReelDeleter/WebStore.swift` | The web view, `reeldeleter://` links, outside links, the page report |
| `ReelDeleter/FilterScript.swift` | The JavaScript that hides tabs and blocks Reels pages |
| `ReelDeleter/FilterSettings.swift` | The options, saved on the phone |
| `ReelDeleter/SettingsView.swift` | The settings sheet |
| `ReelDeleter/RootView.swift` | Puts the web view on screen |

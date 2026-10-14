# Kaset iOS — implementation plan

Branch: `feat/ios-port` (fork: `emoonadev/kaset`). Status lives in [`TRACKER.md`](TRACKER.md).
Decisions and evidence: [ADR-0042](../adr/0042-ios-port-and-background-playback.md),
[spike findings](spike-findings.md).

**Goal:** a native iOS YouTube Music client, sideloaded (not App Store), that keeps
playing with the screen locked, advances through playlists in the background, and is
controllable from the lock screen / Control Center / AirPods.

## Ground rules

1. **One step at a time.** A step is *buildable* when it ends: macOS and iOS both build,
   macOS tests pass. Never leave the branch red between steps.
2. **Every step ends at a gate.** After finishing a step, stop, present its verification
   checklist, and wait for the user to say the step is confirmed. Do not start the next
   step before that.
3. **No file moves, no gratuitous edits to macOS code.** Guard with `#if os(macOS)` /
   `#if canImport(AppKit)` or use a platform typealias. Upstream (`sozercan/kaset`) must
   stay mergeable.
4. **Repo rules still apply** (see `AGENTS.md`): no secrets/cookies in code, logs or
   fixtures; prefer API over WebView except playback/auth; `--self insert`; Swift Testing
   for new tests; `swiftlint --strict` and `swiftformat`; localization catalog + `.lproj`
   mirrors updated together; ADR for architectural changes; ask before UI tests; run
   `$autoreview` before commit/ship on non-trivial steps.
5. **Measure, don't guess** for timing/lifecycle problems: use the diagnostics described
   in [spike findings](spike-findings.md#5-diagnostics-worth-keeping-in-the-app-debug-builds).

## Architecture

```
Sources/Kaset/            macOS app (SwiftPM target "Kaset") — unchanged layout
  Models/ Services/ ViewModels/ Utilities/   ← shared with iOS, compiled in place
  Views/                  macOS-only, except the SingletonPlayerWebView* files
Sources/KasetiOS/         NEW — iOS app entry, iOS UI, iOS platform adapters
Sources/YouTubeAskCore/   Foundation-only; gains an iOS platform + library product
iOS/project.yml           NEW — XcodeGen spec  →  iOS/KasetiOS.xcodeproj (git-ignored)
docs/ios/                 this plan, tracker, spike findings
```

- The iOS target lists `Sources/Kaset/...` paths directly and carries an **exclude
  list** in `iOS/project.yml`. That list is the burn-down: it starts long and shrinks;
  its length is recorded in the tracker.
- `Sources/Kaset/Utilities/Platform.swift` (new, S2) provides `PlatformImage`,
  `PlatformColor`, `PlatformView` typealiases so shared code stops naming `NSImage` etc.
- iOS-only types (audio session, `UIViewRepresentable` host for the player web view,
  app environment, screens) live in `Sources/KasetiOS/`.

### UI reuse (measured on `main` @ 83513f6)

Rule for S7–S13: **reuse the leaves, rebuild the trunk.** Try to include the existing SwiftUI view
files first (adapting layout with size classes / small `#if os()` blocks); write a new iOS view
only when the macOS one is AppKit-bound or desktop-shaped.

| Class | Files | Lines | Examples | iOS plan |
|---|---|---|---|---|
| A — no AppKit, ≤ 2 desktop-ish modifiers | 88 | 19.5k | `HomeView`, `LibraryView`, `PlaylistDetailView`, `ArtistDetailView`, `LyricsView`, `QueueView`, `LoginSheet`, `CarouselShelf`, `SongThumbnailView`, `LikeButton`, `ErrorView`, `ToastView` | Include; adapt padding/columns; swap `.help()` etc. Compile is not yet verified |
| B — SwiftUI but desktop-leaning | 6 | 1.4k | `SearchView` (keyboard shortcuts), settings views (`.help`, fixed frames), `MoodCategoryDetailView` | Include with small edits |
| C — AppKit-bound | 27 | 10.7k | `MainWindow`, `HomeItemCell`, `HomeItemCollectionShelf` (NSViewRepresentable, ADR-0038), `QueueSidePanelView`, `QueueTableCellView`, `MiniPlayerViews`, window controllers | Rewrite in SwiftUI for iOS |
| Web/bridge/window (not UI) | 19 | 10.8k | `SingletonPlayerWebView*`, coordinators | Shared logic, handled in S4 |

Caveats: the desktop shape (sidebar, hover, wide shelves, 1285-line horizontal `PlayerBar`) does not
transfer to a phone — navigation shell, mini player, now-playing and Home shelves are new.
Settings values live in `SettingsManager` (~25 `UserDefaults` keys, shared); the macOS settings
views are plain SwiftUI `Form`/`Section` and are reused where possible.

### Inventory (measured on `main` @ 83513f6)

| Area | Swift files | Importing AppKit | Notes |
|---|---|---|---|
| `Models/` | 45 | 1 (`AppAppearance`) | Nearly free |
| `Services/` | 148 | 6 | `HapticService`, `WebExtensionHost`, `ScriptCommands`, `LastFMService`, `NowPlayingManager`, `YouTubePlayerService` |
| `Services/Audio/` | 5 | 3 import CoreAudio/AudioToolbox | EQ via process taps: macOS-only |
| `ViewModels/` | 27 | 0 | Expected portable |
| `Utilities/` | 17 | 5 | `ImageCache`, `ColorExtractor`, `MainWindowLayout`, `TextInputFocusState`, `PackageResourceLookup` |
| `Views/` | 140 | 22 | macOS UI; iOS gets a new UI |
| App root | 4 | 4 | `KasetApp` (895 lines), `AppDelegate`, window controllers |

Other facts: `PlayerService` and `WebKitManager` only use `NSObject` (portable);
`SingletonPlayerWebView` lives in `Views/MiniPlayerWebView.swift` (2155 lines) next to an
`NSViewRepresentable`; 10 `Services/Player` files reference `SingletonPlayerWebView`;
`Bundle.module` is not used directly (`PackageResourceLookup` finds the resource bundle);
40 files already use `#available(macOS …)`.

## Commands

```bash
# macOS regression (must stay green at every step)
swift build
swift test --skip KasetUITests
swiftlint --strict && swiftformat --lint .

# iOS (from S1 on)
xcodegen generate --spec iOS/project.yml
xcodebuild -project iOS/KasetiOS.xcodeproj -scheme KasetiOS \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Device runs are done by the user from Xcode (Team + signing are theirs).

## Decisions to confirm at S0

| ID | Decision | Recommendation |
|---|---|---|
| D1 | Minimum iOS | **iOS 26.0** (changed from 18.0): the Apple Music–style tab bar + bottom accessory (`tabViewBottomAccessory`, `tabBarMinimizeBehavior`) is iOS 26-only. Personal sideloaded build, so no back-deployment needed. macOS side stays 15.4. |
| D2 | Project generator | **XcodeGen** (dev tool only, not shipped; same as the spike). `.xcodeproj` git-ignored. |
| D3 | Bundle ID / name | **`dev.emoona.kaset`**, display name **Kaset**. Different from upstream `com.sertacozercan.Kaset` so sessions never collide. |
| D4 | v1 scope | YouTube Music only: sign-in, Home, Search, Library, Playlist/Album/Artist, Now Playing, Queue, lock-screen controls. **Out of v1:** YouTube video mode, Ask/AI, extensions, EQ, scripting, scrobbling, synced lyrics. |
| D5 | Device family | **iPhone first.** iPad adaptive layout is backlog. |
| D6 | Native vs page Now Playing | Decided by evidence in S12 (see ADR "Not decided here"). |

## Steps

Status values: ⬜ todo · 🟨 in progress · 🟦 awaiting user verification · ✅ confirmed.

---

### S0 — Plan, ADR, decisions

**Goal:** agree the plan and decisions D1–D5 before touching code.

- Tasks: this document, `TRACKER.md`, ADR-0042, spike findings, `AGENTS.md` pointer. *(done in the commit that adds this file)*
- Build: n/a (docs only).
- **Verify (user):** read PLAN.md; answer D1–D5 (accept recommendations or change them).

---

### S1 — iOS target skeleton builds

**Goal:** an empty iOS app builds from the same repo; macOS untouched.

- `Package.swift`: add `.iOS("26.0")` to `platforms`; add `.library(name: "YouTubeAskCore", targets: ["YouTubeAskCore"])`.
- `iOS/project.yml`: app target `KasetiOS`, bundle id per D3, `UIBackgroundModes=[audio]`,
  `UIFileSharingEnabled=true` (debug log access), local package dependency on the repo root
  for `YouTubeAskCore`, `.gitignore` entry for `iOS/KasetiOS.xcodeproj`.
- `Sources/KasetiOS/KasetiOSApp.swift`: `@main` SwiftUI app showing a placeholder and importing `YouTubeAskCore` to prove linkage.
- **Done when:** iOS simulator build succeeds; `swift build` + `swift test --skip KasetUITests` still green.
- **Verify (user):** open `iOS/KasetiOS.xcodeproj`, run on your iPhone, see the placeholder.
- Risk: Xcode resolves Sparkle even though iOS does not link it (network fetch on first open).

---

### S2 — Shared Models + portable Utilities compile on iOS

**Goal:** the pure data layer is shared.

- Add `Utilities/Platform.swift` (`PlatformImage`, `PlatformColor`, `PlatformView`).
- Make `Models/AppAppearance.swift`, `Utilities/ImageCache.swift`, `ColorExtractor.swift`,
  `PackageResourceLookup.swift` portable (typealiases or `#if os(macOS)` for the AppKit-only parts).
  `MainWindowLayout`, `TextInputFocusState` stay excluded.
- Add `Models/**` and the portable `Utilities/**` to the iOS target; keep the rest in the exclude list.
- **Done when:** iOS build green with Models + Utilities; macOS regression green; exclude-list length recorded.
- **Verify (user):** review the diff of the 4–5 touched macOS files for behavioural no-ops; app still runs on macOS.

---

### S3 — Networking, auth and WebKit plumbing

**Goal:** `YTMusicClient`, auth and cookie handling compile and unit-test on iOS sources.

- Include `Services/API`, `Services/Auth`, `Services/WebKit` (minus `WebExtensionHost`),
  `SettingsManager`, favorites/like managers, `Library`, `Notification`, `ErrorPresenter`,
  `NetworkMonitor`, protocols.
- Keep excluded: `AI`, `Scripting`, `Audio`, `UpdaterService`, `Scrobbling` (D4), `Lyrics` providers if they pull macOS-only code.
- Resolve any `#available(macOS …)` that blocks iOS (use `#available(macOS …, iOS …, *)` or `*`-only).
- Cookie storage: verify the Keychain path on iOS; keep the debug-file backend off-by-default semantics from `AGENTS.md`.
- **Done when:** iOS build green; macOS regression green.
- **Verify (user):** none on device yet; confirm the exclude list and that no auth/cookie code changed behaviour on macOS.

---

### S4 — Playback core on iOS (the critical step)

**Goal:** `PlayerService` + `SingletonPlayerWebView` run on iOS and play in the background.

- Split `Views/MiniPlayerWebView.swift`: wrap the `NSViewRepresentable` part and every `NSView`
  use in `#if os(macOS)`; the `SingletonPlayerWebView` class uses `PlatformView`.
  Include `Views/SingletonPlayerWebView*.swift` in the iOS target.
- `Sources/KasetiOS/PlayerWebViewHost.swift`: `UIViewRepresentable` that mounts the 1×1, alpha-0 web view.
- `Sources/KasetiOS/AudioSessionController.swift`: `.playback` category, activation, interruption and
  route-change handling (resume per `shouldResume`).
- Observer script: add an **iOS-only** block (behind a flag, so macOS is unchanged) with the
  keep-alive `AudioContext` and Media Session handlers from the spike findings.
  Do not release the output context on pause on iOS. Also re-resume it on `statechange`
  (`interrupted`/`suspended`) and `visibilitychange`: pausing in the foreground and then
  locking suspended the whole app in the extended spike run (see spike findings).
- iOS user agent handling per [spike findings §4](spike-findings.md#4-user-agents).
- `Sources/KasetiOS/Debug/PlayerLabView.swift` (debug builds): enter a video/playlist id, play,
  next/previous, live state, and the file log from the spike.
- **Done when:** iOS build green; macOS regression green (incl. the existing player tests).
- **Verify (user, on device) — the spike matrix again, now with real code:**
  1. play a playlist, lock the screen 5 min: audio continues and tracks advance;
  2. pause from lock screen, wait 3 min screen off, play: resumes;
  3. next / previous from lock screen change the track;
  4. same with the 1×1 hidden web view (this is the default here);
  5. pause in the foreground, then lock immediately, wait 3 min, press play on the lock screen: resumes
     (this is the case that failed in the spike).

---

### S5 — Sign-in and session persistence on iOS

**Goal:** a real account can sign in and stays signed in.

- iOS sign-in screen: `WKWebView` with the Mobile Safari UA (and Kaset's passkey suppression if applicable),
  wired to `AuthService`; cookie persistence/restoration through the existing `WebKitManager` paths.
- Account switching entry point (read-only list is enough for now).
- Sign-out clears cookies, data store and Keychain archive.
- **Done when:** builds green; unit tests for any new pure logic.
- **Verify (user, on device):** sign in (Premium and, if possible, a non-Premium account), kill the app,
  relaunch: still signed in; sign out: signed out; no credentials appear in the debug log.

---

### S6 — ViewModels and real data

**Goal:** the shared ViewModel layer runs on iOS against the live API.

- Include `ViewModels/**` (27 files) and any remaining Services they need
  (`Lyrics` read path optional per D4).
- Debug screen listing Home sections and Search results from the real `YTMusicClient`.
- Use `swift run api-explorer` first if any request shape is touched (AGENTS.md "API Discovery").
- **Done when:** builds green; macOS tests green.
- **Verify (user, on device):** the debug lists show your real Home sections and a search returns songs; tapping a row plays it through S4.

---

### S7 — App shell

**Goal:** the navigable skeleton of the real app.

- `AppEnvironment` (iOS): builds and owns the services that `KasetApp` creates today
  (`AuthService`, `PlayerService`, `PlaybackArbiter`, clients, managers) — a trimmed copy, not a refactor of `KasetApp`.
- **Apple Music–style shell** (reference: Apple Music on iOS 26):
  - `TabView` with four tabs — **Home**, **Discover**, **Collections**, **Search**:
    `Tab("Home", systemImage: "house")`, `Tab("Discover", systemImage: "safari")`,
    `Tab("Collections", systemImage: "rectangle.stack")` and `Tab(role: .search)` (detaches to the trailing circle).
    Discover and Collections each host a segmented control (see S9, S10); every tab owns its own `NavigationStack`;
  - `.tabViewBottomAccessory { MiniPlayer() }` for the mini player; read
    `@Environment(\.tabViewBottomAccessoryPlacement)` (`.expanded` / `.inline`) to switch between the full pill
    (artwork, title, artist, play, next) and the compact inline pill (artwork, title, play);
  - `.tabBarMinimizeBehavior(.onScrollDown)` so the tab bar collapses to circle + pill + circle while scrolling;
  - tapping the accessory presents Now Playing with `matchedTransitionSource` + `.navigationTransition(.zoom(...))`;
  - `.glassEffect()` / system Liquid Glass materials only, no custom blur backgrounds.
- Launch routing: signed-out → sign-in; signed-in → tabs.
- **Done when:** builds green.
- Settings entry (gear in the tab bar / profile menu) opening a `Form` backed by the shared `SettingsManager`
  — minimal at first (appearance, audio quality, content language, haptics) so settings exist from the shell on.
- **Verify (user):** launch, sign in, switch tabs, start a track from the debug entry, see the mini player persist across tabs and survive backgrounding; open Settings and change a value that survives relaunch.

---

### S8 — Home and Search screens

- **Home = the same Home as macOS**: same `HomeViewModel` and `HomeView` sections (shelves, cards, pull to refresh,
  load-more). Only the AppKit shelf (`HomeItemCollectionShelf`, ADR-0038) is replaced by a SwiftUI horizontal shelf.
- Search tab with suggestions and result sections (`SearchViewModel`, `SearchView`, `.searchable`).
- Reuse shared item context menus where portable (`Views/SharedViews/*` are macOS; write iOS equivalents).
- **Verify (user):** scroll Home, search, play from results, add to queue / play next from a context menu.

---

### S9 — Discover tab

**Goal:** the Discover tab with a segmented control, reusing the macOS view models.

- Segmented `Picker` (`.pickerStyle(.segmented)`, pinned under the large title): **Explore · Charts · Moods · New releases**.
- Segment content: `ExploreView`/`ExploreViewModel`, `ChartsView`/`ChartsViewModel`,
  `MoodsAndGenresView`/`MoodsAndGenresViewModel` (+ `MoodCategoryDetailView`), `NewReleasesView`/`NewReleasesViewModel`.
- Each segment keeps its own scroll position and loaded state when switching; the selected segment survives relaunch.
- **Verify (user):** switch segments, scroll, pull to refresh, open a chart entry / mood / release, play from each, tab bar minimizes on scroll in every segment.

---

### S10 — Collections tab and detail screens

**Goal:** the Collections tab with a segmented control, plus the detail screens reachable from everywhere.

- Segmented `Picker`: **Library · Liked music · History**.
- Segment content: `LibraryView`/`LibraryViewModel` (playlists, albums, artists),
  Liked music = `PlaylistDetailView` driven by the liked-music `PlaylistDetailViewModel` (same as macOS `NavigationItem.likedMusic`),
  `HistoryView`/`HistoryViewModel`. Signed-out state shows `SignInRequiredView`.
- Playlist / Album / Artist detail screens (`PlaylistDetailView`, `ArtistDetailView`, discography) pushed from any tab,
  with play / shuffle, like, share, add to library.
- Podcasts are not in the tab bar (kept out of v1, see Backlog).
- **Verify (user):** open each segment, play all, shuffle, like a song and see it appear in Liked music, history updates after playing, state survives relaunch.

---

### S11 — Now Playing and Queue

- Full-screen Now Playing (Apple Music layout: large artwork, title/artist + `…` menu, scrubber with elapsed/remaining,
  rewind / play-pause / forward, volume, lyrics · AirPlay · queue row; background tinted from the artwork via `ColorExtractor`),
  with title/artist links, scrubber with seek, transport, like, repeat/shuffle,
  queue sheet with reorder/remove, share.
- **Verify (user):** every control; seek while paused and playing; queue edits are honoured by the next track advance.

---

### S12 — System integration

- Lock screen / Control Center / AirPods: artwork, title, elapsed time, next/previous/play/pause, scrubbing.
  Decide native `NowPlayingManager` vs page Media Session with a measured comparison; record it in ADR-0042.
- Interruptions (call, Siri, other audio), route changes (headphones unplugged → pause), resume rules.
- Deep link / URL scheme `kaset://` parity with `docs/url-scheme.md` where it makes sense.
- **Verify (user):** the interruption/route matrix: phone call, AirPods connect/disconnect, Bluetooth car, other app takes audio.

---

### S13 — Settings, account, polish

- Complete the Settings screen (audio quality, content language, smart shuffle, synced lyrics, haptics, sign out,
  account switcher) and the **iOS behaviour toggles** — new `SettingsManager` keys read by the native layer and
  by the injected page script, each with a localized label and footer text. Candidates:
  *skip ads when possible* (off by default, see Backlog caveat), *resume playback after interruption*,
  *keep playing when headphones disconnect* (default pause), *show now-playing artwork on lock screen*,
  *diagnostics log* (debug). Localization catalog + `.lproj` parity
  (`swift test --filter LocalizationCatalogParityTests`), Dynamic Type, VoiceOver labels, dark mode, haptics.
- **Verify (user):** navigate in two languages; VoiceOver on the player; large text.

---

### S14 — Hardening

- Long sessions (≥ 60 min screen locked), memory/battery measurement (keep-alive `AudioContext` cost),
  WebContent termination → restore position and queue, expired stream recovery, network change/offline, cold start with restored playback.
- **Verify (user):** 1-hour lock-screen run with battery delta noted; kill the web process path (debug menu) recovers.

---

### S15 — Docs, CI, distribution

- `docs/ios/README.md` (build, sideload via Xcode/AltStore, signing limits of free accounts), CHANGELOG/README mention,
  optional GitHub Actions job building the iOS simulator target.
- **Verify (user):** a clean checkout builds following only the docs.

---

## Backlog (not scheduled)

Podcasts tab/segment (macOS has `PodcastsView`; needs the availability service) ·
Ads (free / logged-out accounts): Kaset already detects them (`PlaybackAdDetectionScript`,
`isAd` in the bridge payloads, "Ad" badge in the player bar) but does not skip them. Ads seem to
pause when the page becomes hidden. An opt-in "skip ads when possible" setting is possible but
works against YouTube's terms and could put the account at risk; off by default if ever added.

iPad adaptive layout · YouTube video mode · synced lyrics · scrobbling · Ask/AI (Foundation Models, iOS 26) ·
Widgets / Live Activities · App Intents / Shortcuts · offline queue persistence improvements ·
CarPlay (requires an Apple entitlement, not available for sideloaded builds).

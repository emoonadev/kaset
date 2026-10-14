# Kaset iOS — tracker

Plan: [`PLAN.md`](PLAN.md) · Decisions: [ADR-0042](../adr/0042-ios-port-and-background-playback.md) ·
Branch: `feat/ios-port` on `emoonadev/kaset`.

## Protocol — what to do when the user says "continue selon le plan"

1. Read this file. Find the **first step whose status is not ✅**.
2. If that step is **🟦 awaiting verification**: do **not** start anything new. Remind the
   user what was delivered and its verification checklist (from `PLAN.md`), and ask them to
   confirm or report problems. If they report problems, fix them within the same step.
3. If it is **⬜ todo** (or 🟨 in progress): implement **only that step**, as specified in `PLAN.md`.
   - set it to 🟨 first;
   - keep every build green: run the regression commands from `PLAN.md` (macOS always; iOS from S1);
   - run `$autoreview` for non-trivial steps and handle accepted findings;
   - commit on `feat/ios-port` with a message naming the step (`feat(ios): S4 playback core`),
     push to remote `fork`;
   - set the step to 🟦, fill **Commit** and **Excluded files**, add a line to the Log;
   - present a short summary and the verification checklist, then **stop**.
4. A step becomes ✅ only when the user explicitly confirms it. Record the date.
5. Never skip ahead, never merge two steps, never edit `main`.
   **Test cadence (user decision, 2026-10-14):** the full macOS suite (`swift test --skip KasetUITests`) is
   run only at the checkpoints **S4, S7, S10, S13, S15** (every 3–4 steps). Every other step runs
   `swift build`, the iOS simulator build, `swiftlint` on touched files, and, when it edits existing macOS
   files, a focused `swift test --filter <touched suites>`. Compare checkpoint results with the known
   baseline below; only *new* failures block a step.
6. If reality contradicts the plan (a step is bigger/different than described), stop, say
   so, and propose an amended plan — update `PLAN.md` in the same commit that changes course.

## Decisions (S0)

| ID | Decision | Status |
|---|---|---|
| D1 | Minimum iOS **26.0** (was 18.0; needed for the Apple Music–style bottom accessory) | ✅ accepted 2026-10-14 |
| D2 | XcodeGen for the iOS project | ✅ accepted 2026-10-14 |
| D3 | Bundle id `dev.emoona.kaset`, name "Kaset" | ✅ accepted 2026-10-14 |
| D4 | v1 scope: YouTube Music only (no video mode, AI, extensions, EQ, scripting, scrobbling) | ✅ accepted 2026-10-14 |
| D5 | iPhone first, iPad later | ✅ accepted 2026-10-14 |
| D6 | Native vs page Now Playing | decided in S12 |

## Test baseline (macOS, on `main` @ 83513f6, before any port change)

`swift test --skip KasetUITests`: 3438 tests, **16 issues**, all pre-existing and unrelated to the port:
`PlayerServiceQueueTests` (12) and `PlayerServiceWebQueueSyncTests` (4), caused by `UserDefaults`
`kaset.saved.playbackSession` state shared between tests. Reproduced with the port changes stashed.

## Steps

| ID | Step | Status | Commit | Excluded files | Confirmed |
|---|---|---|---|---|---|
| S0 | Plan, ADR, decisions | ✅ | 6e1e73b…b2846f5 | n/a | 2026-10-14 |
| S1 | iOS target skeleton builds | ✅ | 77bbc64 | 0 (target compiles only `Sources/KasetiOS`) | 2026-10-14 |
| S2 | Shared Models + portable Utilities | ⬜ | | | |
| S3 | Networking, auth, WebKit plumbing | ⬜ | | | |
| S4 | Playback core + background audio on device | ⬜ | | | |
| S5 | Sign-in and session persistence | ⬜ | | | |
| S6 | ViewModels and real data | ⬜ | | | |
| S7 | App shell (tabs + mini player) | ⬜ | | | |
| S8 | Home and Search | ⬜ | | | |
| S9 | Discover tab (Explore · Charts · Moods · New releases) | ⬜ | | | |
| S10 | Collections tab (Library · Liked music · History) + detail screens | ⬜ | | | |
| S11 | Now Playing and Queue | ⬜ | | | |
| S12 | System integration (lock screen, interruptions, routes) | ⬜ | | | |
| S13 | Settings, account, polish | ⬜ | | | |
| S14 | Hardening (long sessions, recovery, battery) | ⬜ | | | |
| S15 | Docs, CI, distribution | ⬜ | | | |

"Excluded files" = number of entries/globs still excluded from the iOS target in
`iOS/project.yml` (the burn-down). Baseline for the shared directories on `main`:
Models 45 · Services 148 · ViewModels 27 · Utilities 17 files.

## Log

| Date | Step | Note |
|---|---|---|
| 2026-10-14 | S1 | Confirmed by the user. Test cadence set to every 3–4 steps (checkpoints S4, S7, S10, S13, S15). |
| 2026-10-14 | S1 | Done, awaiting verification. `Package.swift`: `.iOS("26.0")` + `YouTubeAskCore` library product. New `iOS/project.yml` (XcodeGen) and `Sources/KasetiOS/KasetiOSApp.swift`. `swift build` ✅, iOS simulator build ✅. **Pre-existing failures on macOS tests**: 16 issues in `PlayerServiceQueueTests` / `PlayerServiceWebQueueSyncTests` (UserDefaults `kaset.saved.playbackSession` state shared between tests); reproduced identically with my changes stashed, so not caused by S1. `swiftformat` is not installed here, so formatting of the new file was not checked; `swiftlint` reports no violation in `Sources/KasetiOS` (30 pre-existing ones elsewhere). `$autoreview` skipped: config + placeholder only. `YouTubeAskCore` has no `public` API, so the iOS app only links it. |
| 2026-10-14 | S0 | Tab structure fixed: Home · Discover (Explore/Charts/Moods/New releases) · Collections (Library/Liked music/History) · Search. Steps S10+ renumbered (+1) to add a Collections step. |
| 2026-10-14 | S0 | Layout reference: Apple Music iOS 26 (tab bar + bottom accessory + minimize on scroll + zoom Now Playing). APIs verified in the iOS 27.0 SDK. D1 changed to iOS 26.0. |
| 2026-10-14 | S0 | UI reuse measured (88 files/19.5k lines ready, 6 desktop-leaning, 27 AppKit-bound); settings screen moved into the S7 shell, behaviour toggles (incl. opt-in ad skip) specified in S13. |
| 2026-10-14 | S0 | (extended spike run) 13 min locked, 21 tracks, no app suspension except the *pause in foreground then lock* case; ads pause on backgrounding. Findings added to spike-findings.md. |
| 2026-10-14 | S0 | Spike validated background playback, queue advance, lock-screen next/previous (Media Session), pause/resume (keep-alive AudioContext), hidden 1×1 web view. Fork `emoonadev/kaset` created, branch `feat/ios-port` pushed. Plan, tracker and ADR written. |

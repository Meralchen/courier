# Courier — progress tracker

Updated as work lands. `[x]` done and compiled, `[~]` implemented but not
verified end-to-end in this environment, `[ ]` not implemented.

## Phase 0 — Analysis

- [x] Clone/inspect `allondu/Telegram-iOS_fork` (Swift + Bazel, upstream Telegram iOS).
- [x] Extract the UI language to port: 3-tab shell (Contacts / Chats / Settings),
      44 pt nav bars, 54 pt avatars, 17 pt semibold titles, 15 pt previews,
      0.5 pt insets, blue accent `#007AFF`, grouped settings cards.

## Phase 1 — Real client backbone

- [x] TDLib dependency (`io.github.tdlib-android:core:0.1.1`, JNI for 3 ABIs).
- [x] `TdlibClient`: single `Client`, update stream → `StateFlow`s.
- [x] `setTdlibParameters` with per-install TDLib database directory.
- [x] Ships the OwpenGram application credentials as build-time defaults (blank
      `COURIER_API_ID`/`COURIER_API_HASH` fall back to them), so the app opens
      on the phone screen; Gradle property, env or `local.properties` override.
- [x] Auth state machine: `waitTdlibParameters` → `waitPhoneNumber` →
      `waitCode` → `waitPassword` → `ready`; error surfacing per step.
- [~] Phone login: code path implemented (`setAuthenticationPhoneNumber`),
      needs a real account/phone to verify.
- [x] Logout (`logOut`), session persists across app restarts.
- [x] Connection state labels (`updateConnectionState`).

## Phase 2 — Chat data

- [x] `getChats` + `loadChats`, `updateNewChat`, `updateChatLastMessage`,
      `updateChatTitle`, `updateChatReadInbox`, sorting by main-list position.
- [x] Chat list UI: pinned group, unread badges, previews with "You:" prefix,
      relative timestamps, tap to open.
- [x] `getChatHistory` + `updateNewMessage`, `updateMessageSendSucceeded`,
      `updateMessageSendFailed`, `updateMessageContent`, `updateDeleteMessages`.
- [x] Send text (`sendMessage` + `inputMessageText`), optimistic bubbles,
      read receipts via `viewMessages`.
- [x] Author names for group messages (`updateUser` cache).
- [ ] Media bubbles (photo/video/document previews, download/upload).
- [ ] Voice/video note playback, stickers/GIF rendering.
- [ ] Reactions, replies, forwarding, editing, deletion from UI.
- [ ] Chat management (new chat, join/leave, mute, archive, folders).
- [ ] Secret chats.
- [ ] Server selection (OwpenGram-style `host:port` + RSA key + DC id). Blocked:
      TDLib only connects to Telegram's own DCs; this needs OwpenGram's patched
      network stack instead of TDLib.

## Phase 3 — iOS interface

- [x] Compose design tokens: SF-like type ramp, iOS greys, `#007AFF` accent,
      light + dark palettes.
- [x] Chats screen (large title, glass search, rows, hairlines, badges).
- [x] Chat screen (glass header, bubbles with asymmetric corners, ticks,
      composer with attach/mic/send states).
- [x] Contacts screen (alphabetical sections, avatars, tap to open).
- [x] Settings (profile card, session rows, logout confirmation).
- [x] Liquid glass: `GlassPanel`, `LiquidBackdrop`, `GlassInput`, `GlassButton`.
- [x] Motion: spring press-scale, animated tab/chat transitions, bubble entrance,
      animated logo and drifting backdrop blobs.
- [x] UTF/emoji-safe titles and initials.
- [ ] Avatar photos from Telegram (`chat.photo`/`user.profilePhoto`).
- [ ] Typing indicators, online/last-seen from user statuses.
- [ ] iOS-style swipe-back gesture and context menus.

## Phase 4 — Delivery

- [x] Gradle project builds a debug APK (`dist/Courier-1.0-debug.apk`).
- [x] GitHub Actions workflow builds the APK on push, uploads it as an artifact
      and publishes it to the `courier-debug-latest` GitHub release
      (`https://github.com/Meralchen/courier/releases/download/courier-debug-latest/Courier-debug.apk`).
- [x] Source published: `Meralchen/courier` (default branch) and
      `allondu/Telegram-iOS_fork` (branch `android-port`, same workflow/release).
- [x] Documentation: README, architecture, this tracker.
- [ ] Signed release APK (needs the owner's keystore).
- [ ] Play Store packaging (AAB, per-ABI splits).

## Build verification (2026-11-22)

- CI build (`Android APK` workflow, JDK 17 + SDK 34 + Gradle 8.7): **success**
  for both repositories.
- APK: ~70 MB, package `com.courier.messenger`, versionCode 1, minSdk 26,
  targetSdk 34, label `Courier`, debug-signed, 140 zip entries, TDLib native
  lib present.
- `dist/` now carries the artifact built by the GitHub workflow; the OwpenGram
  `api_id`/`api_hash` are verified present in `classes6.dex`/`classes7.dex`.
  SHA-256 `16c0c7d6c09018b9eb8fa86ec518535a74b94c1a29cfcfabaffd32c693de1dc2`.
- Launcher activity `com.courier.messenger.MainActivity` is exported with the
  MAIN/LAUNCHER intent filter.
- Native libs packaged: `arm64-v8a`, `armeabi-v7a`, `x86_64` (`libtdjni.so`).
- TDLib Java API is in the dex (thousands of `org/drinkless/tdlib` references) —
  the client is not a stub, it ships the real engine.

## Known verification gaps

- No Telegram account or phone number is available in the build sandbox, so the
  login → chat list → send flow has not been exercised against live servers
  here. Everything up to the network boundary compiles and is wired.
- No Android device/emulator in the sandbox: the APK is built and inspected, but
  not launched on-device here.

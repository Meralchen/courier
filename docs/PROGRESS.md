# Courier progress

Updated for the Flutter rewrite. `[x]` implemented and compiled locally, `[~]`
implemented but not verified against live Telegram, `[ ]` not implemented.

## Build verification (2026-11-22)

### Flutter analyze

`flutter analyze` reports **no issues**. Flutter 3.50 deprecates importing
`package:flutter/material.dart` and `package:flutter/cupertino.dart`, so the app
imports `package:material_ui/material_ui.dart` and
`package:cupertino_ui/cupertino_ui.dart` instead.

### APKs

The `Flutter APKs` workflow (`.github/workflows/android.yml`) builds four files
and attaches them to the
[`courier-latest` release](https://github.com/Meralchen/courier/releases/tag/courier-latest):

- `Courier-1.0-arm64.apk` — stable, 64-bit ARM, one TDLib binary. Recommended.
- `Courier-1.0-arm.apk` — stable, 32-bit ARM.
- `Courier-1.0-universal.apk` — stable, both ARM ABIs in one file.
- `Courier-1.0-debug.apk` — debug build; still carries x86_64 for emulators.
- `SHA256SUMS.txt` — checksums for all four. A rebuild replaces the APKs and the
  sums together, so read this file rather than a checksum copied into a document.

Measured on the published files (commit `44cacb0`): **arm64 41,733,872 B
(41.7 MB)**, arm 32.98 MB, universal 98.5 MB, debug ~229 MB.
Downloaded the published arm64 APK and matched its SHA-256
(`ccf58f96…9e07`) against `SHA256SUMS.txt`; `libapp.so` contains `Stickers`,
`Emoji` and the panel's empty-state sentence, and `classes.dex` contains
`InputMessageSticker`, `GetInstalledStickerSets` and `sendSticker`. The earlier
`80853df` APK was verified the same way for story circles (`Unviewed story`,
`GetChatActiveStories` in `classes.dex`). The first universal build was
120 MB because it packed three TDLib binaries (`arm64-v8a`, `armeabi-v7a`,
`x86_64`) and unshrunk dex. R8 cut `classes.dex` from 9.7 MB to 2.8 MB, and the
per-ABI splits leave exactly one `libtdjni.so` in each stable APK. Downloaded
the published arm64 APK and matched its SHA-256 against `SHA256SUMS.txt`;
`aapt2` reports package `com.courier.messenger`, targetSdk 36, native-code
`arm64-v8a`, and `assets/flutter_assets/packages/liquiglass/shaders/liquid_glass.frag`
is present.

### What changed in this build

- Chats follows the current iOS bar: Edit pill, centred title, compose, search,
  filter chips with counts, and real multi-select delete. The floating compose
  button, section headers and footer counter are gone, so nothing overlaps a row.
- Contacts has the Sort pill and last-seen ordering with online/last-seen
  subtitles.
- The tab bar has the trailing search accessory and opens a working local search.
- The composer's emoji button opens the sticker keyboard: recent stickers, the
  first installed regular sets with thumbnails, and an emoji grid that types
  into the draft. Sending uses `InputMessageSticker`, which replaced
  `SendSticker` in this TDLib.
- Settings gains Saved Messages through `CreatePrivateChat` on the own user id.

### Signing and shrinking

- The stable APKs use the debug signing key because this repository has no owner
  keystore; they install normally but are not a Play Store upload.
- R8 is on for release. `android/app/proguard-rules.pro` keeps
  `org.drinkless.tdlib.**`, every class declaring native methods and the
  `com.courier.messenger.telegram.**` bridge, so TDLib's JNI surface survives
  shrinking.

## Performance and material pass (2026-11-22)

The first glass build stuttered. Three costs were removed rather than traded
against quality:

- **Static backdrop.** `LiquidWallpaper` stepped a full-screen gradient at
  ~15 Hz, so every glass panel above it re-ran its backdrop filter at that rate.
  The field is now painted once per size and theme.
- **Material only where iOS has it.** Settings groups, search fields, nav-bar
  icons, empty states and the calls screen are opaque (`SettingsGroup`,
  `IosSearchField`, `NavIconButton`). The chats screen dropped from roughly six
  backdrop filters to two (header, tab bar); Settings went to zero.
- **Fewer rebuilds.** TDLib notifications are coalesced per microtask, file
  progress reports every 5 %, `StoreSelector` narrows list rebuilds, and the
  chat screen caches rows until the message list, media version, typing state or
  theme changes. The pinned chats header no longer changes its shader tint with
  the scroll offset.

Overlay fixes: the jump-to-latest button now lives inside the transcript (it used
to sit over the composer once a reply preview expanded it), and action sheets add
the home-indicator inset to their bottom padding.

Not verified: frame timings on a device. This environment has no emulator
(`/dev/kvm` denied) and no Telegram account, so the improvement is argued from
removed per-frame work, not measured fps.

## Settings overhaul and material switch (2026-11-22)

Settings now follows the current iOS screen: a centred 96 pt avatar with name
and `phone · @username`, Edit in the nav-bar position, then opaque group cards —
Change Profile Photo, Recent Calls, Devices, Notifications and Sounds, Privacy
and Security, Data and Storage, Appearance. Change Profile Photo is a real
upload (`TdApi.SetProfilePhoto` with `InputFileLocal`, then `GetMe` refreshes the
profile); Recent Calls switches to the Calls tab instead of opening a second
history view.

Appearance → Material switches the whole app between `GlassStyle.liquid` and
`GlassStyle.classic`. Classic returns an opaque `Container` from `GlassPanel`
(no shader, no backdrop filter) and replaces the colour field in the shell and
the conversation with a flat background. `test/glass_mode_test.dart` asserts the
`GlassSurface` disappears after the switch.

The tab bar paints exactly one selection shape. It previously drew a resting pill
and a held lens in the same slot, which is what showed two tiles for a moment on
tap. One capsule now swells into the lens and glides between slots; a tap commits
the tapped tab immediately while the shape animates to it.
`test/tab_bar_test.dart` measures the travelling shape mid-glide and checks it
commits the tapped tab.

## Story circles (2026-11-22)

TDLib has no "all stories" call, so `TelegramStories.kt` asks
`GetChatActiveStories` for the private and supergroup chats the engine already
holds (capped at 60), caches the answers in `TelegramEngine.activeStories` and
publishes one payload. `UpdateChatActiveStories` keeps that cache current when a
story is posted, viewed or expires, and republishes without another round trip
through TDLib.

The row appears above the chat list only when somebody has stories. Each circle
is the poster's avatar (58 pt) inside a 66 pt ring with a 2.6 pt stroke: a
`SweepGradient` from blue through violet to pink, rotated to start at twelve
o'clock, while `maxReadStoryId` is behind the newest `StoryInfo.storyId`; the
separator colour once everything is seen. Only `StoryListMain` entries are
shown, newest first, and the label is the first name as in iOS.

Tapping a circle opens that chat. The full-screen player (`OpenStory`,
`GetStory`, story content download) is not part of this build, so the ring is
currently the only story surface.

`test/stories_row_test.dart` covers the unread ring state, the first-name label
and the tap target.

## Phase 1 — Flutter rewrite

- [x] Flutter app scaffold with application id `com.courier.messenger`.
- [x] `liquiglass ^1.0.0` dependency and `LiquidGlass.ensureInitialized()`.
- [x] 45 Dart source files across app, state, telegram, core and UI layers.
- [x] Kotlin TDLib bridge with one client and a two-channel protocol.
- [x] `flutter analyze` clean.
- [x] Debug APK built, installed contents inspected.
- [x] Release build variant with stable signing policy.

## Phase 2 — Telegram

- [x] Authorization state machine and session persistence.
- [~] Phone, code and 2FA login against live servers.
- [x] Chat list, pinned/muted/unread, photos, online/typing.
- [x] Chat history and upward paging.
- [x] Send text; optimistic bubbles and acknowledgements.
- [x] Reply, edit, delete, copy.
- [x] Send photos and view them.
- [x] Shared media grid.
- [x] Read receipts and mark-read.
- [x] Pin/mute/clear/delete chat.
- [x] Contacts from private chats.
- [x] New chat by username.
- [~] Profile editing against live servers.
- [x] Active sessions and termination.
- [x] Cache size and clearing.
- [x] Logout and re-login.
- [x] Sticker keyboard backed by TDLib: recent + installed sets with
  thumbnails, sending through `InputMessageSticker`, emoji grid that types.
- [ ] Voice notes, video, GIF search.
- [ ] Reactions, forwarding, polls, locations.
- [ ] Global message search.
- [ ] Groups/channels administration, folders, archive.
- [ ] Secret chats.
- [ ] VoIP calls.

## Phase 3 — Interface

- [x] Real `liquiglass` shader surfaces.
- [x] Animated wallpaper and glass tab bar.
- [x] iOS type scale, spacing, cards, hairlines and bubbles.
- [x] Glass search, header and composer.
- [x] Spring press feedback and route transitions.
- [x] Light/dark/system appearance, persisted.
- [x] Auth, splash, empty and error states.
- [ ] Tablet/foldable layout.
- [ ] Localization.
- [ ] Themed icon and widgets.

## Phase 4 — Delivery

- [x] GitHub Actions workflow for Flutter 3.50.1 + JDK 17.
- [x] Builds debug and stable APKs in one run.
- [x] Uploads separate artifacts.
- [x] Publishes both APKs and `SHA256SUMS.txt` to the `courier-latest` release.
- [ ] Live end-to-end account test (no phone number in the sandbox).
- [ ] On-device visual review (no KVM, no accessible GPU in the sandbox).
- [ ] Owner keystore / Play Store bundle.

## Known verification gaps

- No Telegram account or phone number is available in the build sandbox, so
  login → chat list → send has not been exercised against live servers. Those
  paths are marked `[~]`.
- `/dev/kvm` is unavailable and `sudo` is blocked, so the Android emulator
  cannot start. The APK is compiled and its contents inspected, but no
  screenshot from a running device exists yet.
- GPU effects cannot be validated in a headless runner; the shader asset is
  present in the APK and `liquiglass` falls back safely where unsupported.

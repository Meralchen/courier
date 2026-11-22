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

Measured on the published files (run #15, commit `d27c02a`): **arm64 41.6 MB**,
arm 32.9 MB, universal 98.4 MB, debug 228.8 MB. The first universal build was
120 MB because it packed three TDLib binaries (`arm64-v8a`, `armeabi-v7a`,
`x86_64`) and unshrunk dex. R8 cut `classes.dex` from 9.7 MB to 2.8 MB, and the
per-ABI splits leave exactly one `libtdjni.so` in each stable APK. Downloaded
the published arm64 APK and matched its SHA-256 against `SHA256SUMS.txt`;
`aapt2` reports package `com.courier.messenger`, targetSdk 36, native-code
`arm64-v8a`, and `assets/flutter_assets/packages/liquiglass/shaders/liquid_glass.frag`
is present.

### Signing and shrinking

- The stable APKs use the debug signing key because this repository has no owner
  keystore; they install normally but are not a Play Store upload.
- R8 is on for release. `android/app/proguard-rules.pro` keeps
  `org.drinkless.tdlib.**`, every class declaring native methods and the
  `com.courier.messenger.telegram.**` bridge, so TDLib's JNI surface survives
  shrinking.

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
- [ ] Voice notes, video, stickers, GIF.
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

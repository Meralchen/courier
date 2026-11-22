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

Both APKs are built by the `Flutter APKs` workflow
(`.github/workflows/android.yml`, run #14 on `cf946bb`) and attached to the
[`courier-latest` release](https://github.com/Meralchen/courier/releases/tag/courier-latest):

- `Courier-1.0-stable.apk` — 120 MB, release build.
- `Courier-1.0-debug.apk` — 229 MB, debug build.
- `SHA256SUMS.txt` — checksums for the files currently attached; a rebuild
  replaces the APKs and the sums together, so read this file rather than a
  checksum copied into a document.

Downloaded the published stable APK and inspected it with `aapt2`/`unzip`:
package `com.courier.messenger`, version 1.0.0, targetSdk 36, `libtdjni.so` for
arm64-v8a, armeabi-v7a and x86_64, and
`assets/flutter_assets/packages/liquiglass/shaders/liquid_glass.frag`.

### Signing

- The stable APK uses the debug signing key because this repository has no owner
  keystore; it installs normally but is not a Play Store upload.
- Minification and resource shrinking are off, so TDLib's JNI classes are not
  stripped accidentally.

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

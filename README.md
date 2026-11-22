# Courier — a real Telegram client in Flutter, with liquid glass

Courier is an Android Telegram client rewritten from Kotlin/Compose into
**Flutter**, using Telegram's official **TDLib** for the network, storage and
update engine and [`shayann07/liquidglass`](https://github.com/shayann07/liquidglass)
for the glass surfaces. It recreates the Telegram-iOS product surface: four
tabs, 54 pt avatars, grouped settings, iOS bubbles, edge-swipe back and a
floating glass tab bar over an animated wallpaper.

This is not a mockup. You sign in with your own phone number, the chat list and
history come from Telegram, and messages you send are actually delivered. TDLib
owns the session database, so a restart keeps you signed in.

## Download

Two APKs are built by GitHub Actions and attached to the
[latest release](https://github.com/Meralchen/courier/releases/tag/courier-latest):

| Build | File | What it is |
| --- | --- | --- |
| Stable, arm64 | [`Courier-1.0-arm64.apk`](https://github.com/Meralchen/courier/releases/download/courier-latest/Courier-1.0-arm64.apk) | 41.6 MB — 64-bit ARM, R8-shrunk with a single TDLib binary. **Start here.** |
| Stable, arm 32-bit | [`Courier-1.0-arm.apk`](https://github.com/Meralchen/courier/releases/download/courier-latest/Courier-1.0-arm.apk) | 32.9 MB — for older or low-end phones |
| Stable, universal | [`Courier-1.0-universal.apk`](https://github.com/Meralchen/courier/releases/download/courier-latest/Courier-1.0-universal.apk) | 98.4 MB — both ARM ABIs in one file |
| Debug | [`Courier-1.0-debug.apk`](https://github.com/Meralchen/courier/releases/download/courier-latest/Courier-1.0-debug.apk) | 229 MB — debug build with diagnostics |

`SHA256SUMS.txt` is published beside them. Requires Android 8.0+ (minSdk 26).

### Why the stable APKs are small

The first Flutter build packed three TDLib binaries (`arm64-v8a`,
`armeabi-v7a`, `x86_64`) and unshrunk dex into one 120 MB file. The release now
ships a **41.6 MB arm64 APK** — about two thirds smaller — because it:

- builds per ABI, so an arm64 phone downloads exactly one TDLib binary;
- runs R8 (`isMinifyEnabled`) and resource shrinking, with keeps only for
  TDLib's JNI surface, the `org.drinkless.tdlib` package and native methods
  (`android/app/proguard-rules.pro`);
- leaves x86_64 out of the stable builds entirely — it exists for emulators, and
  the debug APK still contains it.

The universal APK exists for people who do not know their ABI, and it is still
smaller than the old build because of R8.

## What works

**Telegram**
- Phone-number login, login code and optional 2FA password, with clear per-step
  errors. The session survives restarts through TDLib's local database.
- Live chat list with pinned chats, unread badges, muted chats, last-message
  previews, relative timestamps, online/typing state and chat photos.
- Chat history with upward paging, day dividers, read receipts and an unread
  divider; opening a chat marks it read.
- Sending text and photos from the gallery; replies, edits, deletes and copying
  from a message action sheet.
- Photo viewer, shared-media grid and chat info with members and actions.
- Pin, mute, clear history and delete chat from the chat list or chat info.
- Contacts tab derived from private chats, with alphabetical sections and search.
- New conversation by `@username`.
- Profile editing (first/last name, bio, username), active sessions with
  termination, TDLib cache size and cache clearing, connection diagnostics,
  logout and re-login.

**Interface**
- `liquiglass` `GlassSurface` panels with the package's real fragment shader on
  Impeller, plus an animated colour wallpaper behind them.
- Glass everywhere it belongs: the chats header, conversation bar, tab bar,
  composer, search field, cards, sheets and circular buttons. See
  [Liquid glass](#liquid-glass) for what the material actually does.
- iOS geometry: 34 pt large titles that collapse into a centred nav-bar title,
  54 pt chat avatars, 18 pt bubbles with tails, hairline separators, grouped
  settings cards, tick marks and the blue `#007AFF` accent.
- A tab bar whose selection is a **lens you can hold, drag and throw**: touch
  swells the inset pill into a squircle proud of the bar, the tab under it grows
  and turns blue, dragging follows your finger with a selection tick per tab, and
  a flick carries it to the next tab. Plus a capsule composer that grows to five
  lines, scroll-to-latest, pull-to-refresh, spring press-scale and Hero avatars.
- Light, dark and system appearance, persisted with `shared_preferences`.

## What is not implemented

Voice/video notes, video and animated sticker playback, reactions, polls,
forwarding, global message search, VoIP calls, secret chats, folders/archive,
group administration, contact import, profile-photo upload, push
notifications, multi-account, localization and a tablet layout. See
[docs/ROADMAP.md](docs/ROADMAP.md) for the expanded list and
[docs/PROGRESS.md](docs/PROGRESS.md) for the verified state.

## Build

Requirements: Flutter 3.50.1 (Dart 3.14), JDK 17 and the Android SDK 36.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug

# universal stable (both ARM ABIs, R8-shrunk)
flutter build apk --release --target-platform android-arm,android-arm64

# per-ABI stable APKs (the small ones)
flutter build apk --release --split-per-abi \
  --target-platform android-arm,android-arm64
```

The GitHub workflow builds the debug APK, the universal stable APK and both
per-ABI stable APKs, uploads them as artifacts and publishes them to the
`courier-latest` release on every push to `main`.

### Signing

The release build is signed with the Android debug key on purpose: no owner
keystore is stored in this repository, and that keeps the stable APK
installable. Replace `signingConfig` in `android/app/build.gradle.kts` with a
real keystore before any store distribution.

### Telegram credentials

Telegram requires an `api_id` / `api_hash`. Courier ships with the credentials
the OwpenGram Android client publishes (`lib/config.dart`), so it starts at the
phone screen. For your own build, register a pair at
<https://my.telegram.org> and override them with:

```bash
flutter build apk --release \
  --dart-define=COURIER_API_ID=1234567 \
  --dart-define=COURIER_API_HASH=0123456789abcdef0123456789abcdef
```

## Liquid glass

The material is [`shayann07/liquidglass`](https://github.com/shayann07/liquidglass)'s
production fragment shader over the live backdrop, wrapped by `GlassPanel` in
`lib/ui/components/glass.dart`, which adds what iOS does around the shader:

- **Light from straight overhead.** The package defaults to a top-left light;
  Courier passes `Offset(0, -1)`, the direction iOS 27 measures.
- **Materialisation, not fading.** A panel grows its `materialize` value from 0
  to 1 on first build, so glass condenses into place.
- **A real contour.** A 0.7 pt gradient rim (bright top-left, cool bottom) is
  painted on the edge instead of a flat 1 px border, plus a diagonal sheen that
  sits between the glass and its content.
- **Accessibility.** Increase Contrast is passed to the shader as
  `increasedContrast`; Reduce Motion and accessible navigation turn off
  materialisation, press springs and the wallpaper drift.
- **A bounded wallpaper.** `LiquidWallpaper` drives `CustomPaint` through a
  `ValueNotifier` and steps its phase coarsely (about 15 Hz on a 64 s cycle),
  so the background never rebuilds widgets and never repaints needlessly.

On Android 13+ this is the real AGSL refraction; below 13 the package falls back
to a tinted, rim-lit blur, which the same widgets pick up automatically.

## Telegram-iOS surface

Recreated from the Telegram-iOS client's structure (SwiftUI/UIKit in
[TelegramMessenger/Telegram-iOS](https://github.com/TelegramMessenger/Telegram-iOS)),
not copied from it:

| Surface | Courier |
| --- | --- |
| Chats | 34 pt title that collapses into a centred nav-bar title; pinned glass search field; pinned/muted markers; blue unread pills |
| Conversation | Centred avatar + name + presence in the glass bar; bubbles with tails, ticks, day and unread dividers; scroll-to-latest |
| Composer | Glass capsule input inside a glass bar, attachment/emoji, send that becomes a mic when empty |
| Tabs | Floating glass bar; hold to swell the pill into a lens 4 pt proud of the bar and 16 pt wider than a slot, the tab under it grows to 1.18 and turns accent, drag follows the finger with a haptic per tab, flick throws it, release settles; unread badge and TalkBack actions |
| Settings | Grouped glass cards, 29 pt coloured icons, hairline separators, iOS switches and segmented controls |

## Architecture in one paragraph

Dart owns all UI and state (`lib/`). A single TDLib client lives in
`android/app/src/main/kotlin/com/courier/messenger/telegram/`, behind the
`courier/telegram` method channel and a `courier/telegram/events` event channel.
The Kotlin bridge maps TDLib objects into plain maps, emits updates and keeps
TDLib caches; `TelegramStore` folds those events into Flutter state. The glass
components come from the `liquiglass` package, with Courier-specific bars,
cards and rows in `lib/ui/components/`. Details:
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

The previous Kotlin/Compose implementation is removed from this branch; it
remains in the Git history.

## Branding and licence

TDLib is distributed under the Boost Software License. The Telegram name and
logo belong to Telegram FZ-LLC; Courier uses its own name and icon. The
liquid-glass Flutter implementation is MIT-licensed by its authors.

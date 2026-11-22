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
| Stable, universal | [`Courier-1.0-universal.apk`](https://github.com/Meralchen/courier/releases/download/courier-latest/Courier-1.0-universal.apk) | 98.5 MB — both ARM ABIs in one file |
| Debug | [`Courier-1.0-debug.apk`](https://github.com/Meralchen/courier/releases/download/courier-latest/Courier-1.0-debug.apk) | 229 MB — debug build with diagnostics |

`SHA256SUMS.txt` is published beside them — read it for the current checksums.
Requires Android 8.0+ (minSdk 26).

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
- Static (WebP) stickers render at their aspect ratio inside a conversation;
  animated `.tgs` stickers fall back to the sticker's emoji, since Flutter has
  no Lottie renderer in this build.
- Photo viewer, shared-media grid and chat info with members and actions.
- Pin, mute, clear history and delete chat from the chat list or chat info.
- Contacts tab derived from private chats, with alphabetical sections and search.
- Story circles above the chat list, resolved from TDLib's
  `GetChatActiveStories` and kept live by `UpdateChatActiveStories`: the ring
  sweeps blue → violet → pink while the poster has unviewed stories and turns
  grey once seen. Tapping a circle opens that chat; a full-screen story viewer
  is not built.
- New conversation by `@username`.
- Profile editing (first/last name, bio, username), active sessions with
  termination, TDLib cache size and cache clearing, connection diagnostics,
  logout and re-login.

**Interface**
- `liquiglass` `GlassSurface` panels with the package's real fragment shader on
  Impeller, over a still colour backdrop.
- Glass where Telegram actually puts it: the chats header, conversation bar,
  tab bar, composer, sheets and floating buttons. Content — settings cards,
  search fields, nav-bar icons, rows — is opaque, as it is in Telegram-iOS.
  See [Liquid glass](#liquid-glass) for what the material does and
  [Performance](#performance) for why it is placed that way.
- iOS geometry: 34 pt large titles that collapse into a centred nav-bar title,
  54 pt chat avatars, 18 pt bubbles with tails, hairline separators, grouped
  settings cards, tick marks and the blue `#007AFF` accent.
- A tab bar whose selection is a **lens you can hold, drag and throw**: touch
  swells the inset pill into a squircle proud of the bar, the tab under it grows
  and turns blue, dragging follows your finger with a selection tick per tab, and
  a flick carries it to the next tab. Plus a capsule composer that grows to five
  lines, scroll-to-latest, pull-to-refresh, spring press-scale and Hero avatars.
- Light, dark and system appearance, persisted with `shared_preferences`.
- **Liquid Glass or Classic iOS** as a switch in Settings → Appearance: the
  liquid material runs the shader and the colour field; Classic iOS paints
  opaque bars and cards on the system grouped background with no shader and no
  blur behind the app.

## What is not implemented

Voice/video notes, video playback, reactions, polls, forwarding, global message
search, VoIP calls (the tgcalls engine is not part of this build, so the Calls
tab lists no history and cannot dial), secret chats, folders/archive,
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

## Performance

The first glass build was heavy for three separate reasons, all now removed
rather than hidden behind lower quality:

- **The wallpaper no longer moves.** `LiquidWallpaper` used to step a
  full-screen gradient at ~15 Hz. Every glass surface above it re-runs its
  backdrop filter whenever the backdrop changes, so that drift re-shaded the
  header, composer, tab bar and every card many times a second. The field is now
  painted once per size and theme; scrolling content supplies the motion.
- **Material only where iOS uses it.** Settings cards, search fields, nav-bar
  icons, empty-state circles and the calls screen are opaque. A settings screen
  that used to stack a backdrop filter per card group now uses none; the chats
  screen went from six filters to two (header and tab bar).
- **No rebuild storms.** TDLib emits updates for typing, presence and every few
  kilobytes of a download. Notifications are coalesced per microtask, file
  progress reports only every 5 %, and `StoreSelector` narrows a rebuild to the
  slice a widget draws — a keystroke in one chat no longer rebuilds the shell,
  chat list and contacts behind it.
- **Cached transcript.** The chat screen reuses its built rows until the message
  list object, media version, typing state or theme changes, so typing and
  download progress no longer rebuild every bubble in a long history.
- **Steady header.** The pinned chats header keeps its tint and materialisation
  fixed; only the title cross-fade animates, so the shader is not re-armed on
  every scroll offset.

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
- **A still backdrop.** `LiquidWallpaper` paints a fixed colour field once per
  size and theme. A drifting full-screen gradient forced every panel above it to
  re-filter continuously; that was the app's largest source of jank.

On Android 13+ this is the real AGSL refraction; below 13 the package falls back
to a tinted, rim-lit blur, which the same widgets pick up automatically.

Settings → Appearance → **Material** switches the whole app to Classic iOS, which
returns the opaque `Container` from `GlassPanel` and drops the colour field from
the shell and the conversation. It is both the iOS 13–18 look and the fast path
on GPUs where the shader is expensive.

## Telegram-iOS surface

Recreated from the Telegram-iOS client's structure (SwiftUI/UIKit in
[TelegramMessenger/Telegram-iOS](https://github.com/TelegramMessenger/Telegram-iOS)),
not copied from it:

| Surface | Courier |
| --- | --- |
| Chats | 34 pt title that collapses into a centred nav-bar title; pinned glass search field; story circles with a gradient unread ring; pinned/muted markers; blue unread pills |
| Conversation | Centred avatar + name + presence in the glass bar; bubbles with tails, ticks, day and unread dividers; scroll-to-latest |
| Composer | Glass capsule input inside a glass bar, attachment/emoji, send that becomes a mic when empty |
| Tabs | Floating glass bar; hold to swell the pill into a lens 4 pt proud of the bar and 16 pt wider than a slot, the tab under it grows to 1.18 and turns accent, drag follows the finger with a haptic per tab, flick throws it, release settles; unread badge and TalkBack actions |
| Settings | Centred avatar, name and phone · @username with Edit in the nav-bar position, then opaque group cards: Change Profile Photo, Recent Calls, Devices, Notifications and Sounds, Privacy and Security, Data and Storage, Appearance |

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

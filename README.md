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
| Stable | [`Courier-1.0-stable.apk`](https://github.com/Meralchen/courier/releases/download/courier-latest/Courier-1.0-stable.apk) | Release build, debug-signed so it installs without a private keystore |
| Debug | [`Courier-1.0-debug.apk`](https://github.com/Meralchen/courier/releases/download/courier-latest/Courier-1.0-debug.apk) | Debug build with diagnostics |

`SHA256SUMS.txt` is published beside them. Requires Android 8.0+ (minSdk 26);
the APK includes `arm64-v8a`, `armeabi-v7a` and `x86_64` TDLib binaries.

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
- `liquiglass` `GlassSurface` panels with the package's real fragment shader,
  plus an animated colour wallpaper behind them.
- Glass tab bar, header, composer, search field, cards and circular buttons.
- iOS geometry: 34/44 pt bars, 54 pt avatars, hairline separators, grouped
  settings cards, bubble tails, tick marks and blue `#007AFF` accent.
- Spring press-scale, animated tab/route transitions and bubble entrances.
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
flutter build apk --debug
flutter build apk --release
# build/app/outputs/flutter-apk/app-debug.apk
# build/app/outputs/flutter-apk/app-release.apk
```

The GitHub workflow builds both APKs, uploads them as artifacts and publishes
them to the `courier-latest` release on every push to `main`.

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

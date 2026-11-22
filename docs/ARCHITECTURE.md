# Courier architecture (Flutter)

```
lib/main.dart
└── CourierApp                         MaterialApp, themes, routes
    └── RootGate                       splash → auth → MainShell
        ├── AuthFlow                   phone → code → password
        └── MainShell                  four glass tabs
            ├── ChatListScreen         live chats, search, new chat
            ├── ChatScreen             history, bubbles, composer, actions
            │   └── ChatInfoScreen     members, media, chat actions
            ├── ContactsScreen         private chats by letter
            ├── CallsScreen            empty state (VoIP not implemented)
            └── SettingsScreen         profile, appearance, data, sessions
```

## Layers

### `lib/telegram/`

- `telegram_client.dart` wraps the two platform channels:
  `courier/telegram` for commands and `courier/telegram/events` for updates.
- `telegram_store.dart` is the single source of truth. It owns auth state, the
  chat map, the open chat's message list, the profile, active sessions,
  connection state and transient errors. TDLib events are folded here.
- `models.dart` contains immutable Dart models (`ChatSummary`, `Message`,
  `Profile`, `ChatInfo`, `SessionInfo`), not raw TDLib objects.

TDLib callbacks arrive on Kotlin threads; the bridge serialises them to maps and
the Dart store applies them on the UI isolate. A message send immediately adds
an optimistic message with a local id; the matching TDLib update replaces it.

### `lib/state/`

`AppSettings` persists appearance and notification preferences with
`shared_preferences`; `scopes.dart` exposes the store and settings to the widget
tree through inherited notifiers, so screens rebuild without a third-party
state-management dependency.

### `lib/ui/`

- `components/glass.dart` builds on `liquiglass`'s `GlassSurface` and adds
  Courier's bar, card, field, circular button and animated wallpaper.
- `components/ios_ui.dart` holds the iOS-like grouped list primitives, rows,
  hairlines and section headers.
- `components/avatar.dart`, `sheets.dart`, `photo_viewer.dart` and
  `pressable.dart` provide the shared interactions.
- `auth/`, `chats/`, `chat/`, `contacts/`, `calls/` and `settings/` are feature
  folders. Chat rendering is split into header, bubbles, media, composer and
  actions so no single file owns the whole conversation.

## Android bridge

```
android/app/src/main/kotlin/com/courier/messenger/
├── MainActivity.kt                 registers the plugin
└── telegram/
    ├── CourierTelegramPlugin.kt    method channel + event sink
    ├── TelegramEngine.kt           Client lifecycle, caches, update router
    ├── TelegramAuth.kt             authorization state machine
    ├── TelegramChats.kt            chat list, history, sends, actions
    ├── TelegramProfile.kt          profile, sessions, cache, privacy
    ├── TelegramPublish.kt          outgoing message/photo construction
    ├── TelegramDispatch.kt         channel command dispatch
    ├── TdMapping.kt                TDLib objects → Dart maps
    └── TdFormat.kt                 small formatting helpers
```

There is exactly one `org.drinkless.tdlib.Client`. It is created lazily with
TDLib's update handler, and all commands run on TDLib's async callback API.
`Client.fire { }` is the common fire-and-forget helper; calls that must return a
value expose a Dart `Future`.

### TDLib notes for this build

- The AAR is `io.github.tdlib-android:core:0.1.1`; its Java API is newer than
  many tutorials. `Sender`, `MessageTopic`, `ChatPhotoInfo` and the optional
  parameters on `sendMessage` are used explicitly.
- `updateNewChat`, `updateChatLastMessage`, `updateChatTitle`,
  `updateChatReadInbox`, `updateNewMessage`, `updateMessageContent`,
  `updateMessageSendSucceeded`/`Failed`, `updateDeleteMessages` and
  `updateUser` drive the Dart caches.
- `getChatHistory` pages with `fromMessageId`; `viewMessages` marks a chat read.
- TDLib owns its SQLite database under the app's private files directory.
  Clearing the cache removes downloaded files, not the account session.

## Why Flutter + TDLib

Hand-writing MTProto (DH, SRP, message encryption, update gaps) would be a
security liability and a separate project. TDLib is Telegram's official engine,
so Courier spends its effort on the part that makes it distinctive: the
liquid-glass iOS-like interface and the product flows around it.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config.dart';
import 'models.dart';
import 'telegram_client.dart';

/// App-wide Telegram state. TDLib is the source of truth; this store keeps the
/// last snapshot so widgets can render synchronously and rebuild on updates.
class TelegramStore extends ChangeNotifier {
  TelegramStore([TelegramClient? client])
    : _client = client ?? TelegramClient();

  final TelegramClient _client;
  StreamSubscription<Map<String, Object?>>? _subscription;

  AuthState auth = const AuthState();
  Profile? me;
  String connection = 'Connecting…';
  String tdlibVersion = '';
  String? lastError;
  int? openChatId;
  bool booted = false;

  final Map<int, ChatSummary> _chats = <int, ChatSummary>{};
  final Map<int, List<Message>> _messages = <int, List<Message>>{};
  final Map<int, bool> _hasMore = <int, bool>{};
  final Map<int, ChatInfo> _chatInfos = <int, ChatInfo>{};

  final Map<int, String> filePaths = <int, String>{};
  final Map<int, double> fileProgress = <int, double>{};

  /// Bumped whenever a downloaded path or progress arrives. Views that cache
  /// built rows key off it so a finished photo still replaces its placeholder.
  int filesVersion = 0;

  /// Bumped when the chat list changes. Typing and file updates must not bump
  /// it, so screens showing only the list are not rebuilt for them.
  int chatsVersion = 0;

  List<StickerItem> recentStickers = const <StickerItem>[];
  List<StickerPack> stickerPacks = const <StickerPack>[];
  List<GifItem> savedGifs = const <GifItem>[];
  List<ChatFolder> folders = const <ChatFolder>[];
  int foldersVersion = 0;

  final List<StoryCircle> stories = <StoryCircle>[];
  int storiesVersion = 0;
  bool _storiesRequested = false;
  final Set<int> _requestedFiles = <int>{};

  List<SessionInfo> sessions = const <SessionInfo>[];
  int storageSize = 0;
  int storageCount = 0;

  // ------------------------------------------------------------- selectors

  bool get signedIn => auth.stage == AuthStage.ready;
  bool get needsLogin =>
      auth.stage == AuthStage.waitPhone ||
      auth.stage == AuthStage.waitCode ||
      auth.stage == AuthStage.waitPassword;

  List<ChatSummary> get chats {
    final List<ChatSummary> list = _chats.values
        .where((ChatSummary chat) => !chat.archived)
        .toList();
    list.sort((ChatSummary a, ChatSummary b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.date.compareTo(a.date);
    });
    return list;
  }

  /// TDLib's archive list, newest first. Pinned archived chats lead.
  List<ChatSummary> get archivedChats {
    final List<ChatSummary> list = _chats.values
        .where((ChatSummary chat) => chat.archived)
        .toList();
    list.sort((ChatSummary a, ChatSummary b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.date.compareTo(a.date);
    });
    return list;
  }

  int get archivedUnread => archivedChats.fold<int>(
    0,
    (int sum, ChatSummary chat) => sum + (chat.muted ? 0 : chat.unread),
  );

  List<ChatSummary> get contacts {
    final List<ChatSummary> list = _chats.values
        .where((ChatSummary c) => c.isPrivate && !c.archived)
        .toList();
    list.sort(
      (ChatSummary a, ChatSummary b) =>
          a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return list;
  }

  List<ChatSummary> get pinned =>
      chats.where((ChatSummary chat) => chat.pinned).toList();

  int get totalUnread => chats.fold<int>(
    0,
    (int sum, ChatSummary chat) => sum + (chat.muted ? 0 : chat.unread),
  );

  ChatSummary? chat(int id) => _chats[id];

  ChatInfo? infoFor(int chatId) => _chatInfos[chatId];

  List<Message> messagesFor(int chatId) =>
      _messages[chatId] ?? const <Message>[];

  bool hasMore(int chatId) => _hasMore[chatId] ?? false;

  String pathFor(int fileId, [String fallback = '']) =>
      filePaths[fileId] ?? (fallback.isNotEmpty ? fallback : '');

  SessionInfo? get currentSession {
    for (final SessionInfo session in sessions) {
      if (session.current) return session;
    }
    return null;
  }

  // --------------------------------------------------------- change signals

  bool _notifyScheduled = false;

  /// Coalesces bursts of TDLib events (one history load is dozens of updates)
  /// into a single rebuild per microtask drain instead of one per event.
  void _notify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  // ------------------------------------------------------------------ boot

  Future<void> boot() async {
    if (booted) return;
    booted = true;
    _subscription ??= _client.events.listen(_onEvent);
    try {
      await _client.call('initialize', <String, Object?>{
        'apiId': kCourierApiId,
        'apiHash': kCourierApiHash,
      });
    } catch (error) {
      lastError = error.toString();
      auth = auth.copyWith(stage: AuthStage.error, error: error.toString());
      _notify();
    }
  }

  /// Used by the error screen after a native initialization failure.
  Future<void> retryEngine() async {
    booted = false;
    auth = const AuthState();
    _notify();
    await boot();
  }

  void _onEvent(Map<String, Object?> event) {
    switch (event['type']) {
      case 'auth':
        final AuthStage before = auth.stage;
        final bool becameReady =
            auth.stage != AuthStage.ready && event['stage'] == 'ready';
        auth = AuthState.fromMap(event);
        _notify();
        if (becameReady) {
          // Folder tabs and the sticker keyboard are part of the signed-in
          // shell, so load them as soon as TDLib accepts the session.
          Future<void>.microtask(() async {
            await loadFolders();
            await refreshChats();
          });
        }
        // TDLib closes itself after logout; a fresh client is needed to log in
        // again without restarting the app.
        if (auth.stage == AuthStage.closed && before != AuthStage.closed) {
          booted = false;
          Future<void>.delayed(const Duration(milliseconds: 400), boot);
        }
      case 'chats':
        final List<Object?> raw = asList(event['chats']);
        _chats
          ..clear()
          ..addEntries(
            raw.map((Object? item) {
              final ChatSummary chat = ChatSummary.fromMap(asMap(item));
              return MapEntry<int, ChatSummary>(chat.id, chat);
            }),
          );
        chatsVersion++;
        if (!_storiesRequested) {
          _storiesRequested = true;
          // The engine holds the chats now, so the per-chat story query can
          // resolve them.
          Future<void>.microtask(loadStories);
        }
        _notify();
      case 'messages':
        final int chatId = asInt(event['chatId']);
        final int readOutbox = asInt(event['readOutboxMaxId']);
        final List<Message> list =
            asList(event['messages'])
                .map((Object? item) => Message.fromMap(asMap(item)))
                .map(
                  (Message message) => message.outgoing
                      ? message.copyWith(read: message.id <= readOutbox)
                      : message,
                )
                .toList()
              ..sort((Message a, Message b) => a.id.compareTo(b.id));
        _messages[chatId] = list;
        _hasMore[chatId] = asBool(event['hasMore']);
        final ChatSummary? summary = _chats[chatId];
        if (summary != null && list.isNotEmpty) {
          final Message last = list.last;
          _chats[chatId] = summary.copyWith(preview: last.text);
          chatsVersion++;
        }
        _notify();
      case 'profile':
        me = Profile.fromMap(asMap(event['profile']));
        _notify();
      case 'connection':
        connection = asString(event['state'], 'Offline');
        _notify();
      case 'file':
        final int fileId = asInt(event['fileId']);
        final String path = asString(event['path']);
        final double progress = (event['progress'] as num?)?.toDouble() ?? 0;
        if (path.isNotEmpty) {
          filePaths[fileId] = path;
          fileProgress.remove(fileId);
          filesVersion++;
          _notify();
        } else {
          // A photo download emits progress every few kilobytes; repainting the
          // chat for each one is what makes scrolling a media-heavy chat hitch.
          final double previous = fileProgress[fileId] ?? 0;
          if (progress < 1 && progress - previous < 0.05) return;
          fileProgress[fileId] = progress;
          filesVersion++;
          _notify();
        }
      case 'chatInfo':
        final ChatInfo info = ChatInfo.fromMap(asMap(event['info']));
        _chatInfos[info.chatId] = info;
        _notify();
      case 'stickers':
        _applyStickers(asMap(event['stickers']));
      case 'folders':
        _applyFolders(asList(event['folders']));
      case 'gifs':
        savedGifs = asList(
          event['gifs'],
        ).map((Object? item) => GifItem.fromMap(asMap(item))).toList();
        _notify();
      case 'stories':
        _applyStories(asList(event['stories']));
      case 'storage':
        storageSize = asInt(event['size']);
        storageCount = asInt(event['count']);
        _notify();
      case 'debug':
        tdlibVersion = asString(event['version']);
        _notify();
      case 'error':
        lastError = asString(event['message']);
        _notify();
    }
  }

  String? takeError() {
    final String? message = lastError;
    lastError = null;
    return message;
  }

  // ------------------------------------------------------------------ auth

  Future<void> submitPhone(String phone) async {
    if (auth.stage == AuthStage.closed) {
      booted = false;
      await boot();
    }
    await _guard(
      () => _client.call('submitPhone', <String, Object?>{'phone': phone}),
    );
  }

  Future<void> submitCode(String code) =>
      _guard(() => _client.call('submitCode', <String, Object?>{'code': code}));

  Future<void> submitPassword(String password) => _guard(
    () =>
        _client.call('submitPassword', <String, Object?>{'password': password}),
  );

  Future<void> resendCode() => _guard(() => _client.call('resendCode'));

  Future<void> logout() async {
    openChatId = null;
    _chats.clear();
    _messages.clear();
    _chatInfos.clear();
    stories.clear();
    savedGifs = const <GifItem>[];
    folders = const <ChatFolder>[];
    foldersVersion++;
    _storiesRequested = false;
    storiesVersion++;
    await _guard(() => _client.call('logOut'));
    _notify();
  }

  // ----------------------------------------------------------------- chats

  Future<void> refreshChats() async {
    await _guard(() => _client.call('getChats'));
    await loadStories();
  }

  void _applyStories(List<Object?> raw) {
    stories
      ..clear()
      ..addAll(raw.map((Object? item) => StoryCircle.fromMap(asMap(item))));
    storiesVersion++;
    _notify();
  }

  /// Story circles are decorative: a failure here must never disturb the chat
  /// list, so it is swallowed rather than surfaced as a connection error.
  Future<void> loadStories() async {
    try {
      final List<Object?> raw =
          await _client.invoke<List<Object?>>('stories') ?? const <Object?>[];
      _applyStories(raw);
    } catch (_) {
      // Leave the previous row in place.
    }
  }

  Future<void> openChat(int chatId) async {
    openChatId = chatId;
    _notify();
    await _guard(
      () => _client.call('openChat', <String, Object?>{'chatId': chatId}),
    );
  }

  Future<void> closeChat() async {
    openChatId = null;
    await _guard(() => _client.call('closeChat'));
  }

  Future<void> loadMore(int chatId) => _guard(
    () => _client.call('loadMore', <String, Object?>{'chatId': chatId}),
  );

  Future<void> markRead(int chatId) => _guard(
    () => _client.call('markRead', <String, Object?>{'chatId': chatId}),
  );

  Future<void> sendText(int chatId, String text, {int? replyToId}) => _guard(
    () => _client.call('sendText', <String, Object?>{
      'chatId': chatId,
      'text': text,
      'replyToId': replyToId ?? 0,
    }),
  );

  Future<void> sendPhoto(
    int chatId,
    String path, {
    String caption = '',
    int? replyToId,
  }) => _guard(
    () => _client.call('sendPhoto', <String, Object?>{
      'chatId': chatId,
      'path': path,
      'caption': caption,
      'replyToId': replyToId ?? 0,
    }),
  );

  Future<void> sendVoice(
    int chatId,
    String path,
    int duration, {
    int? replyToId,
  }) => _guard(
    () => _client.call('sendVoice', <String, Object?>{
      'chatId': chatId,
      'path': path,
      'duration': duration,
      'replyToId': replyToId ?? 0,
    }),
  );

  Future<void> forward(int fromChatId, List<int> messageIds, int toChatId) =>
      _guard(
        () => _client.call('forward', <String, Object?>{
          'fromChatId': fromChatId,
          'messageIds': messageIds,
          'toChatId': toChatId,
        }),
      );

  Future<void> editMessage(int chatId, int messageId, String text) => _guard(
    () => _client.call('editMessage', <String, Object?>{
      'chatId': chatId,
      'messageId': messageId,
      'text': text,
    }),
  );

  Future<void> deleteMessages(int chatId, List<int> ids) => _guard(
    () => _client.call('deleteMessages', <String, Object?>{
      'chatId': chatId,
      'messageIds': ids,
    }),
  );

  Future<void> setArchived(int chatId, bool archived) => _guard(
    () => _client.call('setArchived', <String, Object?>{
      'chatId': chatId,
      'archived': archived,
    }),
  );

  Future<void> setPinned(int chatId, bool pinned) => _guard(
    () => _client.call('pinChat', <String, Object?>{
      'chatId': chatId,
      'pinned': pinned,
    }),
  );

  Future<void> setMuted(int chatId, bool muted) => _guard(
    () => _client.call('muteChat', <String, Object?>{
      'chatId': chatId,
      'muted': muted,
    }),
  );

  Future<void> clearHistory(int chatId) => _guard(
    () => _client.call('clearHistory', <String, Object?>{'chatId': chatId}),
  );

  Future<void> deleteChat(int chatId) => _guard(
    () => _client.call('deleteChat', <String, Object?>{'chatId': chatId}),
  );

  Future<void> sendTyping(int chatId, bool typing) => _guard(
    () => _client.call('typing', <String, Object?>{
      'chatId': chatId,
      'typing': typing,
    }),
  );

  Future<void> ensureFile(int fileId) async {
    if (fileId == 0 || filePaths.containsKey(fileId)) return;
    if (!_requestedFiles.add(fileId)) return;
    await _guard(
      () => _client.call('downloadFile', <String, Object?>{'fileId': fileId}),
    );
  }

  Future<int?> openUsername(String username) async {
    try {
      return await _client.invoke<int>('openUsername', <String, Object?>{
        'username': username,
      });
    } catch (error) {
      lastError = error.toString();
      _notify();
      return null;
    }
  }

  Future<void> loadChatInfo(int chatId) => _guard(
    () => _client.call('chatInfo', <String, Object?>{'chatId': chatId}),
  );

  // --------------------------------------------------------------- profile

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String bio,
    required String username,
  }) => _guard(
    () => _client.call('updateProfile', <String, Object?>{
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'username': username,
    }),
  );

  /// Uploads a local image as the account photo. TDLib reads the file itself
  /// and the `profile` update follows, so the header refreshes without a poll.
  Future<void> setProfilePhoto(String path) => _guard(
    () => _client.call('setProfilePhoto', <String, Object?>{'path': path}),
  );

  void _applyStickers(Map<String, Object?> payload) {
    recentStickers = asList(
      payload['recent'],
    ).map((Object? item) => StickerItem.fromMap(asMap(item))).toList();
    stickerPacks = asList(
      payload['sets'],
    ).map((Object? item) => StickerPack.fromMap(asMap(item))).toList();
    _notify();
  }

  /// Loads the panel's stickers once; TDLib caches the answer.
  Future<void> loadStickers() async {
    try {
      final Object? raw = await _client.invoke<Object?>('stickers');
      if (raw is Map) _applyStickers(asMap(raw));
    } catch (_) {
      // The panel stays on its emoji tab if stickers cannot be loaded.
    }
  }

  Future<void> sendSticker(int chatId, StickerItem sticker) => _guard(
    () => _client.call('sendSticker', <String, Object?>{
      'chatId': chatId,
      'fileId': sticker.fileId,
      'emoji': sticker.emoji,
      'width': sticker.width,
      'height': sticker.height,
    }),
  );

  void _applyFolders(List<Object?> raw) {
    folders = raw
        .map((Object? item) => ChatFolder.fromMap(asMap(item)))
        .toList();
    foldersVersion++;
    _notify();
  }

  /// Folder definitions are pushed by TDLib, but asking once at startup means
  /// the tabs are there even if the update arrived before Flutter attached.
  Future<void> loadFolders() async {
    try {
      final List<Object?>? raw = await _client.invoke<List<Object?>>('folders');
      _applyFolders(raw ?? const <Object?>[]);
    } catch (_) {
      // Accounts without folders keep the built-in filter chips.
    }
  }

  Future<void> openFolder(int folderId) => _guard(
    () => _client.call('openFolder', <String, Object?>{'folderId': folderId}),
  );

  Future<void> loadGifs() async {
    try {
      final List<Object?>? raw = await _client.invoke<List<Object?>>('gifs');
      savedGifs = (raw ?? const <Object?>[])
          .map((Object? item) => GifItem.fromMap(asMap(item)))
          .toList();
      _notify();
    } catch (_) {
      // The GIF tab shows its empty state if the account has none.
    }
  }

  Future<void> sendGif(int chatId, GifItem gif) => _guard(
    () => _client.call('sendGif', <String, Object?>{
      'chatId': chatId,
      'fileId': gif.fileId,
      'width': gif.width,
      'height': gif.height,
      'duration': gif.duration,
    }),
  );

  /// The emoji row TDLib offers for this message.
  Future<List<String>> availableReactions(int chatId, int messageId) async {
    try {
      final List<Object?>? raw = await _client.invoke<List<Object?>>(
        'reactions',
        <String, Object?>{'chatId': chatId, 'messageId': messageId},
      );
      return (raw ?? const <Object?>[])
          .map((Object? item) => asString(asMap(item)['emoji']))
          .where((String emoji) => emoji.isNotEmpty)
          .toList();
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> toggleReaction(int chatId, int messageId, String emoji) =>
      _guard(
        () => _client.call('react', <String, Object?>{
          'chatId': chatId,
          'messageId': messageId,
          'emoji': emoji,
        }),
      );

  Future<int?> openSavedMessages() async {
    try {
      return await _client.invoke<int>('savedMessages');
    } catch (error) {
      lastError = error.toString();
      _notify();
      return null;
    }
  }

  Future<void> loadSessions() async {
    try {
      final List<Object?>? raw = await _client.invoke<List<Object?>>(
        'sessions',
      );
      sessions = (raw ?? const <Object?>[])
          .map((Object? item) => SessionInfo.fromMap(asMap(item)))
          .toList();
      _notify();
    } catch (error) {
      lastError = error.toString();
      _notify();
    }
  }

  Future<void> terminateSession(int sessionId) async {
    await _guard(
      () => _client.call('terminateSession', <String, Object?>{
        'sessionId': sessionId,
      }),
    );
    await loadSessions();
  }

  Future<void> loadStorage() async {
    try {
      final Map<String, Object?>? raw = await _client
          .invoke<Map<String, Object?>>('storage');
      if (raw != null) {
        storageSize = asInt(raw['size']);
        storageCount = asInt(raw['count']);
        _notify();
      }
    } catch (error) {
      lastError = error.toString();
      _notify();
    }
  }

  Future<void> clearCache() async {
    try {
      final Map<String, Object?>? raw = await _client
          .invoke<Map<String, Object?>>('clearCache');
      if (raw != null) {
        storageSize = asInt(raw['size']);
        storageCount = asInt(raw['count']);
      }
      _notify();
    } catch (error) {
      lastError = error.toString();
      _notify();
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      lastError = error.toString();
      _notify();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

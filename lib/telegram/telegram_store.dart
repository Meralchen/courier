import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config.dart';
import 'models.dart';
import 'telegram_client.dart';

/// App-wide Telegram state. TDLib is the source of truth; this store keeps the
/// last snapshot so widgets can render synchronously and rebuild on updates.
class TelegramStore extends ChangeNotifier {
  TelegramStore([TelegramClient? client]) : _client = client ?? TelegramClient();

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
  final Set<int> _requestedFiles = <int>{};

  List<SessionInfo> sessions = const <SessionInfo>[];
  int storageSize = 0;
  int storageCount = 0;

  // ------------------------------------------------------------- selectors

  bool get signedIn => auth.stage == AuthStage.ready;
  bool get needsLogin => auth.stage == AuthStage.waitPhone ||
      auth.stage == AuthStage.waitCode ||
      auth.stage == AuthStage.waitPassword;

  List<ChatSummary> get chats {
    final List<ChatSummary> list = _chats.values.toList();
    list.sort((ChatSummary a, ChatSummary b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.date.compareTo(a.date);
    });
    return list;
  }

  List<ChatSummary> get contacts {
    final List<ChatSummary> list =
        _chats.values.where((ChatSummary c) => c.isPrivate).toList();
    list.sort((ChatSummary a, ChatSummary b) =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  List<ChatSummary> get pinned =>
      chats.where((ChatSummary chat) => chat.pinned).toList();

  int get totalUnread => _chats.values.fold<int>(
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
      notifyListeners();
    }
  }

  /// Used by the error screen after a native initialization failure.
  Future<void> retryEngine() async {
    booted = false;
    auth = const AuthState();
    notifyListeners();
    await boot();
  }

  void _onEvent(Map<String, Object?> event) {
    switch (event['type']) {
      case 'auth':
        final AuthStage before = auth.stage;
        auth = AuthState.fromMap(event);
        notifyListeners();
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
        notifyListeners();
      case 'messages':
        final int chatId = asInt(event['chatId']);
        final int readOutbox = asInt(event['readOutboxMaxId']);
        final List<Message> list = asList(event['messages'])
            .map((Object? item) => Message.fromMap(asMap(item)))
            .map((Message message) => message.outgoing
                ? message.copyWith(read: message.id <= readOutbox)
                : message)
            .toList()
          ..sort((Message a, Message b) => a.id.compareTo(b.id));
        _messages[chatId] = list;
        _hasMore[chatId] = asBool(event['hasMore']);
        final ChatSummary? summary = _chats[chatId];
        if (summary != null && list.isNotEmpty) {
          final Message last = list.last;
          _chats[chatId] = summary.copyWith(preview: last.text);
        }
        notifyListeners();
      case 'profile':
        me = Profile.fromMap(asMap(event['profile']));
        notifyListeners();
      case 'connection':
        connection = asString(event['state'], 'Offline');
        notifyListeners();
      case 'file':
        final int fileId = asInt(event['fileId']);
        final String path = asString(event['path']);
        final double progress = (event['progress'] as num?)?.toDouble() ?? 0;
        if (path.isNotEmpty) {
          filePaths[fileId] = path;
          fileProgress.remove(fileId);
        } else {
          fileProgress[fileId] = progress;
        }
        notifyListeners();
      case 'chatInfo':
        final ChatInfo info = ChatInfo.fromMap(asMap(event['info']));
        _chatInfos[info.chatId] = info;
        notifyListeners();
      case 'storage':
        storageSize = asInt(event['size']);
        storageCount = asInt(event['count']);
        notifyListeners();
      case 'debug':
        tdlibVersion = asString(event['version']);
        notifyListeners();
      case 'error':
        lastError = asString(event['message']);
        notifyListeners();
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
        () => _client.call('submitPassword', <String, Object?>{'password': password}),
      );

  Future<void> resendCode() => _guard(() => _client.call('resendCode'));

  Future<void> logout() async {
    openChatId = null;
    _chats.clear();
    _messages.clear();
    _chatInfos.clear();
    await _guard(() => _client.call('logOut'));
    notifyListeners();
  }

  // ----------------------------------------------------------------- chats

  Future<void> refreshChats() => _guard(() => _client.call('getChats'));

  Future<void> openChat(int chatId) async {
    openChatId = chatId;
    notifyListeners();
    await _guard(() => _client.call('openChat', <String, Object?>{'chatId': chatId}));
  }

  Future<void> closeChat() async {
    openChatId = null;
    await _guard(() => _client.call('closeChat'));
  }

  Future<void> loadMore(int chatId) =>
      _guard(() => _client.call('loadMore', <String, Object?>{'chatId': chatId}));

  Future<void> markRead(int chatId) =>
      _guard(() => _client.call('markRead', <String, Object?>{'chatId': chatId}));

  Future<void> sendText(int chatId, String text, {int? replyToId}) =>
      _guard(() => _client.call('sendText', <String, Object?>{
            'chatId': chatId,
            'text': text,
            'replyToId': replyToId ?? 0,
          }));

  Future<void> sendPhoto(
    int chatId,
    String path, {
    String caption = '',
    int? replyToId,
  }) =>
      _guard(() => _client.call('sendPhoto', <String, Object?>{
            'chatId': chatId,
            'path': path,
            'caption': caption,
            'replyToId': replyToId ?? 0,
          }));

  Future<void> editMessage(int chatId, int messageId, String text) =>
      _guard(() => _client.call('editMessage', <String, Object?>{
            'chatId': chatId,
            'messageId': messageId,
            'text': text,
          }));

  Future<void> deleteMessages(int chatId, List<int> ids) =>
      _guard(() => _client.call('deleteMessages', <String, Object?>{
            'chatId': chatId,
            'messageIds': ids,
          }));

  Future<void> setPinned(int chatId, bool pinned) =>
      _guard(() => _client.call('pinChat', <String, Object?>{
            'chatId': chatId,
            'pinned': pinned,
          }));

  Future<void> setMuted(int chatId, bool muted) =>
      _guard(() => _client.call('muteChat', <String, Object?>{
            'chatId': chatId,
            'muted': muted,
          }));

  Future<void> clearHistory(int chatId) =>
      _guard(() => _client.call('clearHistory', <String, Object?>{'chatId': chatId}));

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
      return await _client.invoke<int>(
        'openUsername',
        <String, Object?>{'username': username},
      );
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadChatInfo(int chatId) =>
      _guard(() => _client.call('chatInfo', <String, Object?>{'chatId': chatId}));

  // --------------------------------------------------------------- profile

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String bio,
    required String username,
  }) =>
      _guard(() => _client.call('updateProfile', <String, Object?>{
            'firstName': firstName,
            'lastName': lastName,
            'bio': bio,
            'username': username,
          }));

  Future<void> loadSessions() async {
    try {
      final List<Object?>? raw =
          await _client.invoke<List<Object?>>('sessions');
      sessions = (raw ?? const <Object?>[])
          .map((Object? item) => SessionInfo.fromMap(asMap(item)))
          .toList();
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  Future<void> terminateSession(int sessionId) async {
    await _guard(() => _client.call(
          'terminateSession',
          <String, Object?>{'sessionId': sessionId},
        ));
    await loadSessions();
  }

  Future<void> loadStorage() async {
    try {
      final Map<String, Object?>? raw =
          await _client.invoke<Map<String, Object?>>('storage');
      if (raw != null) {
        storageSize = asInt(raw['size']);
        storageCount = asInt(raw['count']);
        notifyListeners();
      }
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    try {
      final Map<String, Object?>? raw =
          await _client.invoke<Map<String, Object?>>('clearCache');
      if (raw != null) {
        storageSize = asInt(raw['size']);
        storageCount = asInt(raw['count']);
      }
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

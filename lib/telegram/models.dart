import '../core/format.dart';

String asString(Object? v, [String fallback = '']) =>
    v is String ? v : (v == null ? fallback : v.toString());

int asInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

bool asBool(Object? v, [bool fallback = false]) =>
    v is bool ? v : (v is num ? v != 0 : fallback);

Map<String, Object?> asMap(Object? v) {
  if (v is Map<String, Object?>) return v;
  if (v is Map) {
    return v.map<String, Object?>(
      (Object? k, Object? value) => MapEntry<String, Object?>(k.toString(), value),
    );
  }
  return const <String, Object?>{};
}

List<Object?> asList(Object? v) => v is List ? v : const <Object?>[];

enum AuthStage {
  starting,
  waitPhone,
  waitCode,
  waitPassword,
  ready,
  loggingOut,
  closed,
  error;

  static AuthStage parse(Object? v) {
    final String s = asString(v, 'starting');
    return switch (s) {
      'waitPhone' => AuthStage.waitPhone,
      'waitCode' => AuthStage.waitCode,
      'waitPassword' => AuthStage.waitPassword,
      'ready' => AuthStage.ready,
      'loggingOut' => AuthStage.loggingOut,
      'closed' => AuthStage.closed,
      'error' => AuthStage.error,
      _ => AuthStage.starting,
    };
  }
}

class AuthState {
  const AuthState({
    this.stage = AuthStage.starting,
    this.error,
    this.busy = false,
    this.codeLength = 5,
    this.passwordHint,
  });

  factory AuthState.fromMap(Map<String, Object?> m) => AuthState(
        stage: AuthStage.parse(m['stage']),
        error: (m['error'] as String?)?.trim().isEmpty ?? true
            ? null
            : m['error'] as String?,
        busy: asBool(m['busy']),
        codeLength: asInt(m['codeLength'], 5).clamp(3, 8),
        passwordHint: m['passwordHint'] as String?,
      );

  final AuthStage stage;
  final String? error;
  final bool busy;
  final int codeLength;
  final String? passwordHint;

  bool get signedIn => stage == AuthStage.ready;
  bool get signingIn =>
      stage == AuthStage.waitPhone ||
      stage == AuthStage.waitCode ||
      stage == AuthStage.waitPassword;

  AuthState copyWith({
    AuthStage? stage,
    String? error,
    bool? busy,
    int? codeLength,
    String? passwordHint,
    bool clearError = false,
  }) =>
      AuthState(
        stage: stage ?? this.stage,
        error: clearError ? null : (error ?? this.error),
        busy: busy ?? this.busy,
        codeLength: codeLength ?? this.codeLength,
        passwordHint: passwordHint ?? this.passwordHint,
      );
}

class ChatSummary {
  const ChatSummary({
    required this.id,
    required this.title,
    required this.preview,
    required this.date,
    required this.unread,
    required this.pinned,
    required this.muted,
    required this.isPrivate,
    required this.lastOutgoing,
    required this.userId,
    required this.online,
    required this.typing,
    required this.photoFileId,
    required this.photoPath,
    required this.lastMessageId,
    required this.readOutboxMaxId,
    required this.readInboxMaxId,
    required this.unreadMention,
    required this.isGroup,
    required this.memberCount,
    required this.lastSeen,
  });

  factory ChatSummary.fromMap(Map<String, Object?> m) => ChatSummary(
        id: asInt(m['id']),
        title: asString(m['title'], 'Chat'),
        preview: asString(m['preview']),
        date: asInt(m['date']),
        unread: asInt(m['unread']),
        pinned: asBool(m['pinned']),
        muted: asBool(m['muted']),
        isPrivate: asBool(m['isPrivate']),
        lastOutgoing: asBool(m['lastOutgoing']),
        userId: asInt(m['userId']),
        online: asBool(m['online']),
        typing: asBool(m['typing']),
        photoFileId: asInt(m['photoFileId']),
        photoPath: asString(m['photoPath']),
        lastMessageId: asInt(m['lastMessageId']),
        readOutboxMaxId: asInt(m['readOutboxMaxId']),
        readInboxMaxId: asInt(m['readInboxMaxId']),
        unreadMention: asBool(m['unreadMention']),
        isGroup: asBool(m['isGroup']),
        memberCount: asInt(m['memberCount']),
        lastSeen: asInt(m['lastSeen']),
      );

  final int id;
  final String title;
  final String preview;
  final int date;
  final int unread;
  final bool pinned;
  final bool muted;
  final bool isPrivate;
  final bool lastOutgoing;
  final int userId;
  final bool online;
  final bool typing;
  final int photoFileId;
  final String photoPath;
  final int lastMessageId;
  final int readOutboxMaxId;
  final int readInboxMaxId;
  final bool unreadMention;
  final bool isGroup;
  final int memberCount;
  final int lastSeen;

  String get initials => initialsOf(title);

  ChatSummary copyWith({
    String? preview,
    int? date,
    int? unread,
    bool? pinned,
    bool? muted,
    bool? online,
    bool? typing,
    String? photoPath,
    int? lastMessageId,
    int? readOutboxMaxId,
    int? readInboxMaxId,
    bool? unreadMention,
  }) =>
      ChatSummary(
        id: id,
        title: title,
        preview: preview ?? this.preview,
        date: date ?? this.date,
        unread: unread ?? this.unread,
        pinned: pinned ?? this.pinned,
        muted: muted ?? this.muted,
        isPrivate: isPrivate,
        lastOutgoing: lastOutgoing,
        userId: userId,
        online: online ?? this.online,
        typing: typing ?? this.typing,
        photoFileId: photoFileId,
        photoPath: photoPath ?? this.photoPath,
        lastMessageId: lastMessageId ?? this.lastMessageId,
        readOutboxMaxId: readOutboxMaxId ?? this.readOutboxMaxId,
        readInboxMaxId: readInboxMaxId ?? this.readInboxMaxId,
        unreadMention: unreadMention ?? this.unreadMention,
        isGroup: isGroup,
        memberCount: memberCount,
        lastSeen: lastSeen,
      );
}

class Message {
  const Message({
    required this.id,
    required this.chatId,
    required this.text,
    required this.date,
    required this.outgoing,
    required this.pending,
    required this.failed,
    required this.sender,
    required this.senderId,
    required this.kind,
    required this.photoFileId,
    required this.photoPath,
    required this.width,
    required this.height,
    required this.fileName,
    required this.fileSize,
    required this.duration,
    required this.edited,
    required this.replyToId,
    required this.replyToText,
    required this.replyToSender,
    required this.albumId,
    required this.isService,
    required this.read,
    required this.isChannelPost,
  });

  factory Message.fromMap(Map<String, Object?> m) => Message(
        id: asInt(m['id']),
        chatId: asInt(m['chatId']),
        text: asString(m['text']),
        date: asInt(m['date']),
        outgoing: asBool(m['outgoing']),
        pending: asBool(m['pending']),
        failed: asBool(m['failed']),
        sender: asString(m['sender']),
        senderId: asInt(m['senderId']),
        kind: asString(m['kind'], 'text'),
        photoFileId: asInt(m['photoFileId']),
        photoPath: asString(m['photoPath']),
        width: asInt(m['width']),
        height: asInt(m['height']),
        fileName: asString(m['fileName']),
        fileSize: asInt(m['fileSize']),
        duration: asInt(m['duration']),
        edited: asBool(m['edited']),
        replyToId: asInt(m['replyToId']),
        replyToText: asString(m['replyToText']),
        replyToSender: asString(m['replyToSender']),
        albumId: asInt(m['albumId']),
        isService: asBool(m['isService']),
        read: asBool(m['read']),
        isChannelPost: asBool(m['isChannelPost']),
      );

  final int id;
  final int chatId;
  final String text;
  final int date;
  final bool outgoing;
  final bool pending;
  final bool failed;
  final String sender;
  final int senderId;
  final String kind;
  final int photoFileId;
  final String photoPath;
  final int width;
  final int height;
  final String fileName;
  final int fileSize;
  final int duration;
  final bool edited;
  final int replyToId;
  final String replyToText;
  final String replyToSender;
  final int albumId;
  final bool isService;
  final bool read;
  final bool isChannelPost;

  bool get hasPhoto =>
      kind == 'photo' || kind == 'video' || kind == 'animation';

  bool get hasMedia => photoFileId > 0 || photoPath.isNotEmpty;

  Message copyWith({bool? read, bool? pending, bool? failed}) => Message(
        id: id,
        chatId: chatId,
        text: text,
        date: date,
        outgoing: outgoing,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
        sender: sender,
        senderId: senderId,
        kind: kind,
        photoFileId: photoFileId,
        photoPath: photoPath,
        width: width,
        height: height,
        fileName: fileName,
        fileSize: fileSize,
        duration: duration,
        edited: edited,
        replyToId: replyToId,
        replyToText: replyToText,
        replyToSender: replyToSender,
        albumId: albumId,
        isService: isService,
        read: read ?? this.read,
        isChannelPost: isChannelPost,
      );
}

class Profile {
  const Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.username,
    required this.bio,
    required this.photoFileId,
    required this.photoPath,
  });

  factory Profile.fromMap(Map<String, Object?> m) => Profile(
        id: asInt(m['id']),
        firstName: asString(m['firstName']),
        lastName: asString(m['lastName']),
        phone: asString(m['phone']),
        username: asString(m['username']),
        bio: asString(m['bio']),
        photoFileId: asInt(m['photoFileId']),
        photoPath: asString(m['photoPath']),
      );

  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String username;
  final String bio;
  final int photoFileId;
  final String photoPath;

  String get name {
    final String full = '$firstName $lastName'.trim();
    return full.isEmpty ? 'Courier user' : full;
  }

  String get initials => initialsOf(name);
}

class ChatInfo {
  const ChatInfo({
    required this.chatId,
    required this.title,
    required this.about,
    required this.phone,
    required this.username,
    required this.photoFileId,
    required this.photoPath,
    required this.memberCount,
    required this.isPrivate,
    required this.muted,
    required this.pinned,
    required this.isBlocked,
  });

  factory ChatInfo.fromMap(Map<String, Object?> m) => ChatInfo(
        chatId: asInt(m['chatId']),
        title: asString(m['title'], 'Chat'),
        about: asString(m['about']),
        phone: asString(m['phone']),
        username: asString(m['username']),
        photoFileId: asInt(m['photoFileId']),
        photoPath: asString(m['photoPath']),
        memberCount: asInt(m['memberCount']),
        isPrivate: asBool(m['isPrivate']),
        muted: asBool(m['muted']),
        pinned: asBool(m['pinned']),
        isBlocked: asBool(m['isBlocked']),
      );

  final int chatId;
  final String title;
  final String about;
  final String phone;
  final String username;
  final int photoFileId;
  final String photoPath;
  final int memberCount;
  final bool isPrivate;
  final bool muted;
  final bool pinned;
  final bool isBlocked;
}

class SessionInfo {
  const SessionInfo({
    required this.id,
    required this.current,
    required this.device,
    required this.application,
    required this.location,
    required this.ip,
    required this.lastActive,
  });

  factory SessionInfo.fromMap(Map<String, Object?> m) => SessionInfo(
        id: asInt(m['id']),
        current: asBool(m['current']),
        device: asString(m['device'], 'Unknown device'),
        application: asString(m['application']),
        location: asString(m['location']),
        ip: asString(m['ip']),
        lastActive: asInt(m['lastActive']),
      );

  final int id;
  final bool current;
  final String device;
  final String application;
  final String location;
  final String ip;
  final int lastActive;
}

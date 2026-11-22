import 'dart:math' as math;
import 'dart:ui' show Color;

const List<String> _months = <String>[
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> _weekdays = <String>[
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

/// Telegram-style initials: two words give one letter each, one word gives two.
String initialsOf(String title) {
  final List<String> words = title
      .trim()
      .split(RegExp(r'\s+'))
      .where((String w) => w.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return '#';
  String first(String w) {
    final List<int> runes = w.runes.toList();
    if (runes.isEmpty) return '';
    return String.fromCharCode(runes.first).toUpperCase();
  }

  if (words.length == 1) {
    final List<int> runes = words.first.runes.toList();
    final String a = String.fromCharCode(runes.first).toUpperCase();
    final String b =
        runes.length > 1 ? String.fromCharCode(runes[1]).toLowerCase() : '';
    return '$a$b';
  }
  return first(words[0]) + first(words[1]);
}

/// Keeps digits only and prefixes a plus, as TDLib expects.
String normalizePhone(String raw) {
  final String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? '' : '+$digits';
}

String two(int n) => n.toString().padLeft(2, '0');

String messageTime(int epochSeconds) {
  if (epochSeconds <= 0) return '';
  final DateTime t =
      DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000).toLocal();
  return '${two(t.hour)}:${two(t.minute)}';
}

String chatTimestamp(int epochSeconds) {
  if (epochSeconds <= 0) return '';
  final DateTime now = DateTime.now();
  final DateTime t =
      DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000).toLocal();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(t.year, t.month, t.day);
  final int diff = today.difference(day).inDays;
  if (diff == 0) return messageTime(epochSeconds);
  if (diff == 1) return 'Yesterday';
  if (diff > 1 && diff < 7) return _weekdays[t.weekday - 1];
  if (t.year == now.year) return '${t.day}.${two(t.month)}.';
  return '${two(t.day)}.${two(t.month)}.${two(t.year % 100)}';
}

String dayLabel(int epochSeconds) {
  final DateTime now = DateTime.now();
  final DateTime t =
      DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000).toLocal();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(t.year, t.month, t.day);
  final int diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (t.year == now.year) return '${t.day} ${_months[t.month - 1]}';
  return '${t.day} ${_months[t.month - 1]} ${t.year}';
}

bool sameDay(int a, int b) {
  if (a == 0 || b == 0) return a == b;
  final DateTime da =
      DateTime.fromMillisecondsSinceEpoch(a * 1000).toLocal();
  final DateTime db =
      DateTime.fromMillisecondsSinceEpoch(b * 1000).toLocal();
  return da.year == db.year && da.month == db.month && da.day == db.day;
}

String lastSeenLabel(int epochSeconds) {
  if (epochSeconds <= 0) return 'last seen recently';
  final Duration d = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000),
  );
  if (d.inMinutes < 1) return 'last seen just now';
  if (d.inMinutes < 60) return 'last seen ${d.inMinutes} min ago';
  if (d.inHours < 24) return 'last seen ${d.inHours} h ago';
  if (d.inDays == 1) return 'last seen yesterday';
  return 'last seen ${chatTimestamp(epochSeconds)}';
}

String fileSizeLabel(int bytes) {
  if (bytes <= 0) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

const List<List<Color>> _avatarGradients = <List<Color>>[
  <Color>[Color(0xFF5EB5F7), Color(0xFF3B8DE0)],
  <Color>[Color(0xFF7ED97E), Color(0xFF3CB371)],
  <Color>[Color(0xFFF7B26A), Color(0xFFE8894A)],
  <Color>[Color(0xFFC48AF0), Color(0xFF8E5BD6)],
  <Color>[Color(0xFFF58FA6), Color(0xFFD9587A)],
  <Color>[Color(0xFF63D3CE), Color(0xFF2FA8A3)],
  <Color>[Color(0xFFB8BCC4), Color(0xFF8E939B)],
  <Color>[Color(0xFF9AB8F5), Color(0xFF5C7FD6)],
];

List<Color> avatarGradient(int id) =>
    _avatarGradients[math.max(0, id).abs() % _avatarGradients.length];

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'models.dart';

/// A voice/chat room. The network topic is a hash of name + password, so a
/// password-protected room can't be found or joined without knowing both.
class RoomInfo {
  static const String defaultName = 'general';
  static const String _scheme = 'cocord://join';

  final String name;
  final String password;

  const RoomInfo(this.name, [this.password = '']);

  bool get isPrivate => password.isNotEmpty;

  /// Normalized name used for hashing (case/space-insensitive).
  String get normalized => normalize(name);

  /// Topic-safe 32-hex-char key.
  String get key {
    final input = utf8.encode('$normalized\n$password');
    return sha256.convert(input).toString().substring(0, 32);
  }

  static String normalize(String raw) {
    final s = raw
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    final cut = s.length > Limits.maxRoomName
        ? s.substring(0, Limits.maxRoomName).trim()
        : s;
    return cut.isEmpty ? defaultName : cut;
  }

  /// Builds a room from user input, applying length limits.
  factory RoomInfo.fromInput(String name, String password) {
    final pw = password.length > Limits.maxPassword
        ? password.substring(0, Limits.maxPassword)
        : password;
    return RoomInfo(normalize(name), pw);
  }

  @override
  bool operator ==(Object other) => other is RoomInfo && other.key == key;

  @override
  int get hashCode => key.hashCode;

  // ---- Invites -----------------------------------------------------------

  /// Shareable text containing a tappable link.
  String get invite {
    final link = Uri.parse(_scheme).replace(queryParameters: {
      'room': name,
      if (isPrivate) 'pass': password,
    });
    return 'Join me on Cocord!\nRoom: $name${isPrivate ? ' (private)' : ''}\n$link';
  }

  /// Extracts a room from a pasted invite, a bare link, or plain room name.
  static RoomInfo? parse(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final m = RegExp('cocord://join\\?[^\\s]+').firstMatch(t);
    if (m == null) return RoomInfo.fromInput(t.split('\n').first, '');
    final q = Uri.tryParse(m.group(0)!)?.queryParameters;
    final room = q?['room'];
    if (room == null || room.trim().isEmpty) return null;
    return RoomInfo.fromInput(room, q?['pass'] ?? '');
  }

  // ---- Persistence -------------------------------------------------------

  Map<String, String> toJson() => {'n': name, 'p': password};

  static RoomInfo? fromJson(Object? j) {
    if (j is! Map) return null;
    final n = j['n'];
    final p = j['p'];
    if (n is! String || p is! String) return null;
    return RoomInfo.fromInput(n, p);
  }
}

/// Safe extraction helpers for untrusted network payloads.
class MsgUtils {
  /// Returns [v] as a trimmed string capped at [max] chars, or null when it
  /// isn't a non-empty string. Control characters are stripped.
  static String? str(Object? v, int max) {
    if (v is! String) return null;
    final clean = v.replaceAll(RegExp(r'[\u0000-\u0008\u000B-\u001F\u007F]'), '');
    final s = clean.trim();
    if (s.isEmpty) return null;
    return s.length > max ? s.substring(0, max) : s;
  }

  static bool flag(Object? v) => v == true;
}

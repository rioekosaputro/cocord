import 'package:flutter/services.dart';

import '../room.dart';
import 'boombox_mixin.dart';
import 'ptt_mixin.dart';
import 'radio_base.dart';
import 'session_mixin.dart';

/// Switching rooms: join by name/password, by pasted invite, or by tapping a
/// `cocord://join` link.
mixin RoomsMixin on RadioBase, BoomboxMixin, PttMixin, SessionMixin {
  static const _links = MethodChannel('com.cocord.app/links');

  void enterRoom(RoomInfo room) {
    if (room == settings.room) {
      toast?.call('You are already in #${room.name}');
      return;
    }
    settings.room = room;
    settings.remember(room);
    settings.save();
    notifyListeners();
    switchRoom();
  }

  /// Joins by typed name/password. False when the name is empty.
  bool joinNamed(String name, String password) {
    if (name.trim().isEmpty) return false;
    enterRoom(RoomInfo.fromInput(name, password));
    return true;
  }

  /// Accepts a room name or a whole pasted invite. False if unusable.
  bool joinFromText(String text) {
    final room = RoomInfo.parse(text);
    if (room == null) return false;
    enterRoom(room);
    return true;
  }

  void forgetRoom(RoomInfo room) {
    settings.recents.remove(room);
    settings.save();
    notifyListeners();
  }

  /// Opens rooms from `cocord://join` links (cold start and while running).
  Future<void> attachLinks() async {
    _links.setMethodCallHandler((call) async {
      if (call.method == 'onLink') _openLink(call.arguments);
    });
    try {
      _openLink(await _links.invokeMethod<String>('initialLink'));
    } catch (_) {}
  }

  void _openLink(Object? link) {
    if (link is String && link.startsWith('cocord://')) joinFromText(link);
  }
}

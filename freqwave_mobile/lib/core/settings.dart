import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'room.dart';

class AppSettings {
  String displayName = 'Guest';
  int colorIndex = 0;
  RoomInfo room = const RoomInfo(RoomInfo.defaultName);
  List<RoomInfo> recents = [];

  /// false = open mic like a voice call; true = hold a button to talk.
  bool pttMode = false;
  bool volumeKeyPtt = true;
  double boomboxVolume = 0.65;
  int station = 0;
  bool syncBoombox = true;

  /// Preferred audio devices, remembered by label (ids change between runs).
  String inputLabel = '';
  String outputLabel = '';

  /// Empty = use the built-in public broker list.
  String brokerHost = '';
  int brokerPort = 1883;
  String turnUrl = '';
  String turnUser = '';
  String turnPass = '';

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    final s = AppSettings();
    s._loadProfile(p);
    s._loadAudio(p);
    s._loadNetwork(p);
    return s;
  }

  void _loadProfile(SharedPreferences p) {
    displayName = sanitizeName(p.getString('displayName') ??
        'Guest${100 + DateTime.now().millisecond % 900}');
    colorIndex = (p.getInt('colorIndex') ?? 0).clamp(0, kMemberColors.length - 1);
    room = _decodeRoom(p.getString('room')) ?? room;
    recents = (p.getStringList('recents') ?? [])
        .map(_decodeRoom)
        .whereType<RoomInfo>()
        .take(Limits.maxRecents)
        .toList();
  }

  void _loadAudio(SharedPreferences p) {
    pttMode = p.getBool('pttMode') ?? pttMode;
    volumeKeyPtt = p.getBool('volumeKeyPtt') ?? volumeKeyPtt;
    boomboxVolume = p.getDouble('boomboxVolume') ?? boomboxVolume;
    station = (p.getInt('station') ?? 0).clamp(0, kStations.length - 1);
    syncBoombox = p.getBool('syncBoombox') ?? syncBoombox;
    inputLabel = p.getString('inputLabel') ?? '';
    outputLabel = p.getString('outputLabel') ?? '';
  }

  void _loadNetwork(SharedPreferences p) {
    brokerHost = p.getString('brokerHost') ?? '';
    brokerPort = p.getInt('brokerPort') ?? 1883;
    turnUrl = p.getString('turnUrl') ?? '';
    turnUser = p.getString('turnUser') ?? '';
    turnPass = p.getString('turnPass') ?? '';
  }

  static RoomInfo? _decodeRoom(String? raw) {
    if (raw == null) return null;
    try {
      return RoomInfo.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  /// Moves [r] to the front of the recent-rooms list.
  void remember(RoomInfo r) {
    recents
      ..remove(r)
      ..insert(0, r);
    if (recents.length > Limits.maxRecents) {
      recents = recents.take(Limits.maxRecents).toList();
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('displayName', displayName);
    await p.setInt('colorIndex', colorIndex);
    await p.setString('room', jsonEncode(room.toJson()));
    await p.setStringList(
        'recents', recents.map((r) => jsonEncode(r.toJson())).toList());
    await _saveAudio(p);
    await _saveNetwork(p);
  }

  Future<void> _saveAudio(SharedPreferences p) async {
    await p.setBool('pttMode', pttMode);
    await p.setBool('volumeKeyPtt', volumeKeyPtt);
    await p.setDouble('boomboxVolume', boomboxVolume);
    await p.setInt('station', station);
    await p.setBool('syncBoombox', syncBoombox);
    await p.setString('inputLabel', inputLabel);
    await p.setString('outputLabel', outputLabel);
  }

  Future<void> _saveNetwork(SharedPreferences p) async {
    await p.setString('brokerHost', brokerHost);
    await p.setInt('brokerPort', brokerPort);
    await p.setString('turnUrl', turnUrl);
    await p.setString('turnUser', turnUser);
    await p.setString('turnPass', turnPass);
  }
}

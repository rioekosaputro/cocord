import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models.dart';
import '../signaling.dart';
import 'radio_base.dart';

/// Synced boombox: internet radio streams, shared play/station state across
/// the room, and auto-ducking while anyone is transmitting.
mixin BoomboxMixin on RadioBase {
  static const double _duckFactor = 0.25;

  final AudioPlayer player = AudioPlayer();
  bool playing = false;
  bool buffering = false;
  String? boomError;
  int _loaded = -1;

  Station get station => kStations[settings.station];

  void initBoombox() {
    player.playerStateStream.listen((s) {
      playing = s.playing;
      buffering = s.processingState == ProcessingState.loading ||
          s.processingState == ProcessingState.buffering;
      notifyListeners();
    }, onError: (Object e) => _fail('$e'));
    updateDuck();
  }

  @override
  Json boomboxState() => {'s': settings.station, 'p': playing};

  Future<void> togglePlay() async {
    if (playing) {
      await player.pause();
    } else {
      await _start();
    }
    _broadcastState();
  }

  Future<void> selectStation(int index, {bool remote = false}) async {
    final i = index % kStations.length;
    settings.station = i < 0 ? i + kStations.length : i;
    settings.save();
    notifyListeners();
    if (playing || !remote) await _start();
    if (!remote) _broadcastState();
  }

  Future<void> nextStation(int delta) => selectStation(settings.station + delta);

  Future<void> _start() async {
    boomError = null;
    try {
      if (_loaded != settings.station) {
        await player.setUrl(station.url);
        _loaded = settings.station;
      }
      player.play(); // completes only when the stream ends
    } catch (e) {
      _fail('$e');
    }
  }

  void _fail(String detail) {
    debugPrint('[Boombox] $detail');
    _loaded = -1;
    boomError = 'Stream unavailable. Check your connection.';
    notifyListeners();
  }

  void setBoomboxVolume(double v) {
    settings.boomboxVolume = v;
    updateDuck();
    notifyListeners();
  }

  void commitBoomboxVolume() => settings.save();

  @override
  void updateDuck() {
    final duck = transmitting || anyRemoteTx;
    final base = isDeafened ? 0.0 : settings.boomboxVolume;
    player.setVolume(duck ? base * _duckFactor : base);
  }

  void _broadcastState() {
    if (!settings.syncBoombox) return;
    signaling?.sendBroadcast({'t': 'bx', ...boomboxState()});
  }

  /// Apply boombox state announced by another peer.
  Future<void> applyRemoteBoombox(Json bx) async {
    if (!settings.syncBoombox) return;
    final s = bx['s'];
    final p = bx['p'];
    if (s is! int || s < 0 || s >= kStations.length || p is! bool) return;
    if (s != settings.station) {
      settings.station = s;
      notifyListeners();
      if (p || playing) await _start();
    }
    if (p && !playing) await _start();
    if (!p && playing) await player.pause();
  }

  Future<void> disposeBoombox() => player.dispose();
}

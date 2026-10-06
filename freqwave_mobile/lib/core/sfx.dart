import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'synth.dart';

/// Plays the synthesized radio sounds (squelch, roger beep, soundboard, hiss).
/// Every effect owns a pre-loaded player so triggering it is near-instant.
class Sfx {
  final Map<String, AudioPlayer> _players = {};
  final Map<String, Future<AudioPlayer?>> _loading = {};
  Directory? _dir;
  bool muted = false;
  double _staticVolume = 0.12;
  bool _staticOn = false;

  static const _staticKey = 'static';

  Future<void> init() async {
    try {
      final tmp = await getTemporaryDirectory();
      _dir = await Directory('${tmp.path}/sfx').create(recursive: true);
    } catch (e) {
      debugPrint('[Sfx] temp dir error: $e');
      return;
    }
    // Warm everything up in the background.
    final builders = <String, Uint8List Function()>{
      'squelch_up': () => Synth.squelch(keyup: true),
      'squelch_down': () => Synth.squelch(keyup: false),
      'roger': Synth.rogerBeep,
      for (final s in kSoundboard) s.key: s.build,
    };
    for (final e in builders.entries) {
      _load(e.key, e.value);
    }
  }

  Future<AudioPlayer?> _load(String key, Uint8List Function() build) {
    return _loading.putIfAbsent(key, () async {
      final dir = _dir;
      if (dir == null) return null;
      try {
        final file = File('${dir.path}/$key.wav');
        await file.writeAsBytes(build(), flush: true);
        final p = AudioPlayer(
          handleInterruptions: false, handleAudioSessionActivation: false);
        await p.setFilePath(file.path);
        _players[key] = p;
        return p;
      } catch (e) {
        debugPrint('[Sfx] load $key failed: $e');
        return null;
      }
    });
  }

  Future<void> _play(String key, Uint8List Function() build,
      {double volume = 1.0}) async {
    if (muted) return;
    final p = await _load(key, build);
    if (p == null) return;
    try {
      await p.setVolume(volume);
      await p.seek(Duration.zero);
      // Don't await: play() completes when the clip finishes.
      p.play();
    } catch (e) {
      debugPrint('[Sfx] play $key failed: $e');
    }
  }

  Future<void> squelchKeyup() =>
      _play('squelch_up', () => Synth.squelch(keyup: true));

  Future<void> squelchTail() =>
      _play('squelch_down', () => Synth.squelch(keyup: false));

  Future<void> rogerBeep() => _play('roger', Synth.rogerBeep);

  Future<void> soundboard(String key) async {
    final def = kSoundboard.where((s) => s.key == key);
    if (def.isEmpty) return;
    await _play(key, def.first.build);
  }

  // ---- Ambient static ----------------------------------------------------

  Future<void> setStatic(bool on, double volume) async {
    _staticOn = on;
    _staticVolume = volume;
    final p = await _load(_staticKey, Synth.staticLoop);
    if (p == null) return;
    try {
      await p.setVolume(volume.clamp(0.0, 1.0));
      if (on && !muted) {
        await p.setLoopMode(LoopMode.one);
        if (!p.playing) p.play();
      } else if (p.playing) {
        await p.pause();
      }
    } catch (e) {
      debugPrint('[Sfx] static error: $e');
    }
  }

  Future<void> setMuted(bool value) async {
    muted = value;
    if (value) {
      for (final p in _players.values) {
        if (p.playing) await p.pause();
      }
    } else {
      await setStatic(_staticOn, _staticVolume);
    }
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}

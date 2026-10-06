import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'synth.dart';

/// Plays the short synthesized sounds (soundboard, join/leave chimes).
/// Every effect owns a pre-loaded player so triggering it is near-instant.
class Sfx {
  final Map<String, AudioPlayer> _players = {};
  final Map<String, Future<AudioPlayer?>> _loading = {};
  Directory? _dir;
  bool muted = false;

  Future<void> init() async {
    try {
      final tmp = await getTemporaryDirectory();
      _dir = await Directory('${tmp.path}/sfx').create(recursive: true);
    } catch (e) {
      debugPrint('[Sfx] temp dir error: $e');
      return;
    }
    final builders = <String, Uint8List Function()>{
      'chime_up': () => Synth.chime(up: true),
      'chime_down': () => Synth.chime(up: false),
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

  Future<void> _play(String key, Uint8List Function() build) async {
    if (muted) return;
    final p = await _load(key, build);
    if (p == null) return;
    try {
      await p.seek(Duration.zero);
      p.play(); // completes when the clip ends; don't await
    } catch (e) {
      debugPrint('[Sfx] play $key failed: $e');
    }
  }

  Future<void> joinChime() =>
      _play('chime_up', () => Synth.chime(up: true));

  Future<void> leaveChime() =>
      _play('chime_down', () => Synth.chime(up: false));

  Future<void> soundboard(String key) async {
    final def = kSoundboard.where((s) => s.key == key);
    if (def.isEmpty) return;
    await _play(key, def.first.build);
  }

  Future<void> setMuted(bool value) async {
    muted = value;
    if (!value) return;
    for (final p in _players.values) {
      if (p.playing) await p.pause();
    }
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}

import 'dart:async';

import 'package:flutter/services.dart';

import 'boombox_mixin.dart';
import 'radio_base.dart';

/// Voice call controls: open mic (default) or push-to-talk, mute, deafen and
/// the "who is speaking" detection driven by real audio levels.
mixin VoiceMixin on RadioBase, BoomboxMixin {
  static const _channel = MethodChannel('com.cocord.app/hardware_ptt');
  static const _pollEvery = Duration(milliseconds: 300);
  static const _micTail = Duration(milliseconds: 150);
  static const _speakLevel = 0.012;
  static const _holdTicks = 2;

  bool micMuted = false;
  bool pttHeld = false;

  Timer? _monitor;
  Timer? _micRelease;
  bool _polling = false;
  final Map<String, int> _quiet = {};
  int _localQuiet = 0;

  /// Whether the microphone is currently sending audio.
  bool get micOpen =>
      !isDeafened && (settings.pttMode ? pttHeld : !micMuted);

  void applyMic() => mesh?.setTransmit(micOpen);

  // ---- Hardware PTT key --------------------------------------------------

  void attachHardwareKeys() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPttKeyDown') startTransmit();
      if (call.method == 'onPttKeyUp') stopTransmit();
    });
    syncVolumeKey();
  }

  /// The volume-down key only acts as PTT in push-to-talk mode.
  void syncVolumeKey() {
    final on = settings.pttMode && settings.volumeKeyPtt;
    _channel.invokeMethod<void>('setVolumeKeyEnabled', on).catchError((_) {});
  }

  // ---- Push-to-talk ------------------------------------------------------

  void startTransmit() {
    if (!settings.pttMode || pttHeld) return;
    if (!_canUseMic()) return;
    HapticFeedback.heavyImpact();
    _micRelease?.cancel();
    pttHeld = true;
    applyMic();
    notifyListeners();
  }

  void stopTransmit() {
    if (!pttHeld) return;
    HapticFeedback.mediumImpact();
    pttHeld = false;
    _micRelease = Timer(_micTail, applyMic);
    notifyListeners();
  }

  bool _canUseMic() {
    if (!joined) {
      toast?.call('Connect first');
      return false;
    }
    if (mesh?.hasMic != true) {
      toast?.call('Microphone unavailable. Allow it in Settings.');
      return false;
    }
    return true;
  }

  // ---- Mute / deafen / mode ---------------------------------------------

  void toggleMicMute() {
    if (!micMuted && !_canUseMic()) return;
    micMuted = !micMuted;
    if (!micMuted && isDeafened) _setDeafened(false);
    applyMic();
    notifyListeners();
  }

  void toggleDeafen() => _setDeafened(!isDeafened);

  void _setDeafened(bool value) {
    isDeafened = value;
    mesh?.setRemoteMuted(value);
    sfx.setMuted(value);
    applyMic();
    updateDuck();
    notifyListeners();
  }

  void setPttMode(bool on) {
    settings.pttMode = on;
    pttHeld = false;
    settings.save();
    syncVolumeKey();
    applyMic();
    notifyListeners();
  }

  // ---- Speaking detection -----------------------------------------------

  void startMonitor() {
    _monitor?.cancel();
    _monitor = Timer.periodic(_pollEvery, (_) => _poll());
  }

  Future<void> _poll() async {
    final voice = mesh;
    if (_polling || voice == null) return;
    _polling = true;
    try {
      final lv = await voice.levels();
      final changed = _applyLocal(lv.local > _speakLevel && micOpen) |
          _applyRemote(lv.remote);
      if (changed) {
        updateDuck();
        notifyListeners();
      }
    } finally {
      _polling = false;
    }
  }

  bool _applyLocal(bool loud) {
    final was = transmitting;
    _localQuiet = loud ? 0 : _localQuiet + 1;
    transmitting = loud || (was && _localQuiet < _holdTicks);
    return was != transmitting;
  }

  bool _applyRemote(Map<String, double> levels) {
    var changed = false;
    for (final p in peers.values) {
      final loud = (levels[p.id] ?? 0) > _speakLevel;
      final q = loud ? 0 : (_quiet[p.id] ?? 0) + 1;
      _quiet[p.id] = q;
      final now = loud || (p.transmitting && q < _holdTicks);
      if (now != p.transmitting) {
        p.transmitting = now;
        changed = true;
      }
    }
    return changed;
  }

  void stopVoice() {
    _monitor?.cancel();
    _monitor = null;
    _micRelease?.cancel();
    pttHeld = false;
    transmitting = false;
    _quiet.clear();
  }
}

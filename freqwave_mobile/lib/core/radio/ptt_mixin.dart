import 'dart:async';

import 'package:flutter/services.dart';

import 'boombox_mixin.dart';
import 'radio_base.dart';

/// Push-to-talk: on-screen button, open mic and hardware keys.
mixin PttMixin on RadioBase, BoomboxMixin {
  static const _channel = MethodChannel('com.cocord.app/hardware_ptt');
  static const _micTail = Duration(milliseconds: 150);

  Timer? _micRelease;

  void attachHardwareKeys() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPttKeyDown') startTransmit();
      if (call.method == 'onPttKeyUp') stopTransmit();
    });
    syncVolumeKey();
  }

  void syncVolumeKey() {
    _channel
        .invokeMethod<void>('setVolumeKeyEnabled', settings.volumeKeyPtt)
        .catchError((_) {});
  }

  void startTransmit() {
    if (transmitting) return;
    if (!joined) {
      toast?.call('Tune in first');
      return;
    }
    if (mesh?.hasMic != true) {
      toast?.call('Microphone unavailable. Allow it in Settings.');
      return;
    }
    HapticFeedback.heavyImpact();
    _micRelease?.cancel();
    transmitting = true;
    mesh!.setTransmit(true);
    _announce(true);
    if (settings.squelch) sfx.squelchKeyup();
    updateDuck();
    notifyListeners();
  }

  void stopTransmit({bool force = false}) {
    if (!transmitting || (openMic && !force)) return;
    HapticFeedback.mediumImpact();
    transmitting = false;
    _micRelease = Timer(_micTail, () => mesh?.setTransmit(false));
    _announce(false);
    _endTone();
    updateDuck();
    notifyListeners();
  }

  void setOpenMic(bool on) {
    openMic = on;
    if (on) {
      startTransmit();
      if (!transmitting) openMic = false;
    } else {
      stopTransmit(force: true);
    }
    notifyListeners();
  }

  void _announce(bool on) => signaling?.sendBroadcast(
      {'t': 'tx', 'on': on, 'cs': settings.callsign});

  void _endTone() {
    if (settings.rogerBeep) sfx.rogerBeep();
    if (settings.squelch) {
      Future.delayed(_micTail, sfx.squelchTail);
    }
  }

  void releaseMicNow() {
    _micRelease?.cancel();
    transmitting = false;
    openMic = false;
    mesh?.setTransmit(false);
  }
}

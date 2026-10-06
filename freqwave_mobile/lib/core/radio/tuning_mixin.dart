import 'dart:async';

import '../models.dart';
import 'boombox_mixin.dart';
import 'ptt_mixin.dart';
import 'radio_base.dart';
import 'session_mixin.dart';

/// Frequency dial, presets and the scanner.
mixin TuningMixin on RadioBase, BoomboxMixin, PttMixin, SessionMixin {
  static const _scanDwell = Duration(seconds: 5);

  Timer? _scanTimer;
  int _scanIndex = 0;

  void tune(double freq, {bool keepScanning = false}) {
    final f = Freq.clamp(freq);
    if (f == settings.frequency) return;
    if (!keepScanning) stopScan();
    settings.frequency = f;
    settings.save();
    if (settings.squelch) sfx.squelchTail();
    notifyListeners();
    switchRoom();
  }

  void step(double delta) => tune(settings.frequency + delta);

  /// Parses user text such as "433.92"; returns false when invalid.
  bool tuneText(String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    if (v == null || v < Freq.min || v > Freq.max) return false;
    tune(v);
    return true;
  }

  void toggleScan() => scanning ? stopScan() : _startScan();

  void _startScan() {
    scanning = true;
    notifyListeners();
    _scanStep();
    _scanTimer = Timer.periodic(_scanDwell, (_) => _scanStep());
  }

  void _scanStep() {
    if (peers.isNotEmpty || anyRemoteTx) {
      addSystem('Signal found on $freqLabel MHz');
      stopScan();
      return;
    }
    _scanIndex = (_scanIndex + 1) % kPresets.length;
    tune(kPresets[_scanIndex].freq, keepScanning: true);
  }

  void stopScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
    if (!scanning) return;
    scanning = false;
    notifyListeners();
  }
}

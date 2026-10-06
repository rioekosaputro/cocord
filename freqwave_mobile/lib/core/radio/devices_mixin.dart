import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'radio_base.dart';

/// Choosing the microphone and speaker (built-in, wired, Bluetooth…).
/// Lists are only available while the voice engine is running.
mixin DevicesMixin on RadioBase {
  List<MediaDeviceInfo> inputDevices = [];
  List<MediaDeviceInfo> outputDevices = [];
  String? activeInputId;
  String? activeOutputId;

  @override
  Future<void> onVoiceReady() async {
    navigator.mediaDevices.ondevicechange = (_) => refreshDevices();
    await refreshDevices();
    await _restoreSaved();
  }

  @override
  void onVoiceStopped() {
    navigator.mediaDevices.ondevicechange = null;
    inputDevices = [];
    outputDevices = [];
    activeInputId = null;
    activeOutputId = null;
  }

  Future<void> refreshDevices() async {
    try {
      final all = await navigator.mediaDevices.enumerateDevices();
      inputDevices = all.where((d) => d.kind == 'audioinput').toList();
      outputDevices = all.where((d) => d.kind == 'audiooutput').toList();
      _dropMissingSelection();
      notifyListeners();
    } catch (e) {
      debugPrint('[Devices] enumerate failed: $e');
    }
  }

  void _dropMissingSelection() {
    if (!inputDevices.any((d) => d.deviceId == activeInputId)) {
      activeInputId = null;
    }
    if (!outputDevices.any((d) => d.deviceId == activeOutputId)) {
      activeOutputId = null;
    }
  }

  Future<void> _restoreSaved() async {
    final inLabel = settings.inputLabel;
    final outLabel = settings.outputLabel;
    final inDev = inputDevices.where((d) => d.label == inLabel);
    final outDev = outputDevices.where((d) => d.label == outLabel);
    if (inLabel.isNotEmpty && inDev.isNotEmpty) await chooseInput(inDev.first);
    if (outLabel.isNotEmpty && outDev.isNotEmpty) {
      await chooseOutput(outDev.first);
    }
  }

  Future<void> chooseInput(MediaDeviceInfo d) async {
    try {
      await Helper.selectAudioInput(d.deviceId);
      activeInputId = d.deviceId;
      settings.inputLabel = d.label;
      settings.save();
    } catch (e) {
      toast?.call('Could not switch microphone');
      debugPrint('[Devices] input failed: $e');
    }
    notifyListeners();
  }

  Future<void> chooseOutput(MediaDeviceInfo d) async {
    try {
      await Helper.selectAudioOutput(d.deviceId);
      activeOutputId = d.deviceId;
      settings.outputLabel = d.label;
      settings.save();
    } catch (e) {
      toast?.call('Could not switch speaker');
      debugPrint('[Devices] output failed: $e');
    }
    notifyListeners();
  }
}

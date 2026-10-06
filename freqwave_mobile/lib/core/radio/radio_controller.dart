import 'dart:async';

import '../models.dart';
import '../settings.dart';
import 'boombox_mixin.dart';
import 'devices_mixin.dart';
import 'incoming_mixin.dart';
import 'ptt_mixin.dart';
import 'radio_base.dart';
import 'session_mixin.dart';
import 'social_mixin.dart';
import 'tuning_mixin.dart';

/// Single source of truth for the UI. Behaviour is split across the mixins.
class RadioController extends RadioBase
    with
        BoomboxMixin,
        PttMixin,
        IncomingMixin,
        SessionMixin,
        TuningMixin,
        SocialMixin,
        DevicesMixin {
  bool ready = false;

  Future<void> init() async {
    settings = await AppSettings.load();
    await sfx.init();
    initBoombox();
    attachHardwareKeys();
    await sfx.setStatic(settings.staticNoise, settings.staticVolume);
    ready = true;
    notifyListeners();
    unawaited(join());
  }

  // ---- Settings ----------------------------------------------------------

  void _persist() {
    settings.save();
    notifyListeners();
  }

  void setCallsign(String raw) {
    settings.callsign = sanitizeCallsign(raw);
    addSystem('Callsign set to ${settings.callsign}');
    sendHello();
    _persist();
  }

  void setVolumeKeyPtt(bool v) {
    settings.volumeKeyPtt = v;
    syncVolumeKey();
    _persist();
  }

  void setRogerBeep(bool v) {
    settings.rogerBeep = v;
    _persist();
  }

  void setSquelch(bool v) {
    settings.squelch = v;
    _persist();
  }

  void setStatic(bool on, [double? volume]) {
    settings.staticNoise = on;
    settings.staticVolume = volume ?? settings.staticVolume;
    sfx.setStatic(on, settings.staticVolume);
    _persist();
  }

  void setSyncBoombox(bool v) {
    settings.syncBoombox = v;
    _persist();
  }

  void setNetwork({
    required String brokerHost,
    required int brokerPort,
    required String turnUrl,
    required String turnUser,
    required String turnPass,
  }) {
    settings.brokerHost = brokerHost.trim();
    settings.brokerPort = brokerPort;
    settings.turnUrl = turnUrl.trim();
    settings.turnUser = turnUser;
    settings.turnPass = turnPass;
    _persist();
    toast?.call('Network settings apply the next time you tune in');
  }

  Future<void> toggleMute() async {
    muted = !muted;
    await sfx.setMuted(muted);
    mesh?.setRemoteMuted(muted);
    updateDuck();
    notifyListeners();
  }

  Future<void> reconnect() async {
    await leave();
    await join();
  }

  @override
  void dispose() {
    stopScan();
    leave();
    sfx.dispose();
    disposeBoombox();
    super.dispose();
  }
}

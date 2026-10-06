import 'dart:async';

import '../models.dart';
import '../settings.dart';
import 'boombox_mixin.dart';
import 'devices_mixin.dart';
import 'incoming_mixin.dart';
import 'voice_mixin.dart';
import 'radio_base.dart';
import 'session_mixin.dart';
import 'rooms_mixin.dart';
import 'social_mixin.dart';

/// Single source of truth for the UI. Behaviour is split across the mixins.
class RadioController extends RadioBase
    with
        BoomboxMixin,
        VoiceMixin,
        IncomingMixin,
        SessionMixin,
        RoomsMixin,
        SocialMixin,
        DevicesMixin {
  bool ready = false;

  Future<void> init() async {
    settings = await AppSettings.load();
    await sfx.init();
    initBoombox();
    attachHardwareKeys();
    settings.remember(settings.room);
    unawaited(attachLinks());
    ready = true;
    notifyListeners();
    unawaited(join());
  }

  // ---- Settings ----------------------------------------------------------

  void _persist() {
    settings.save();
    notifyListeners();
  }

  void setProfile({String? name, int? colorIndex}) {
    if (name != null) settings.displayName = sanitizeName(name);
    if (colorIndex != null) settings.colorIndex = colorIndex;
    sendHello();
    _persist();
  }

  void setVolumeKeyPtt(bool v) {
    settings.volumeKeyPtt = v;
    syncVolumeKey();
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

  Future<void> reconnect() async {
    await leave();
    await join();
  }

  @override
  void dispose() {
    leave();
    sfx.dispose();
    disposeBoombox();
    super.dispose();
  }
}

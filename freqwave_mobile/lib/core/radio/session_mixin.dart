import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

import '../background_service.dart';
import '../models.dart';
import '../signaling.dart';
import '../voice_mesh.dart';
import 'boombox_mixin.dart';
import 'voice_mixin.dart';
import 'radio_base.dart';

/// Connecting to / leaving the room: permissions, MQTT link, voice mesh,
/// presence heartbeat and the background service.
mixin SessionMixin on RadioBase, BoomboxMixin, VoiceMixin {
  static const _helloEvery = Duration(seconds: 10);
  static const _pruneEvery = Duration(seconds: 5);
  static const _roomDebounce = Duration(milliseconds: 400);

  Timer? _helloTimer;
  Timer? _pruneTimer;
  Timer? _switchTimer;

  Future<void> join() async {
    if (joined || joining) return;
    joining = true;
    error = null;
    notifyListeners();
    await _askPermissions();
    if (!await _connect()) {
      joining = false;
      error = 'Cannot reach the signaling network. Check your internet.';
      notifyListeners();
      return;
    }
    await _startVoice();
    _enterRoom();
    joined = true;
    joining = false;
    _startTimers();
    startMonitor();
    sfx.joinChime();
    await BackgroundService.start(text: _status(), micGranted: micGranted);
    notifyListeners();
  }

  Future<void> _askPermissions() async {
    micGranted = (await Permission.microphone.request()).isGranted;
    await BackgroundService.requestNotificationPermission();
  }

  Future<bool> _connect() async {
    final s = Signaling(myId,
        brokerHost: settings.brokerHost, brokerPort: settings.brokerPort)
      ..onBroadcast = handleBroadcast
      ..onDirect = handleDirect
      ..onState = _onNet
      ..onReconnected = sendHello;
    signaling = s;
    return s.connect();
  }

  void _onNet(NetState s) {
    net = s;
    notifyListeners();
  }

  Future<void> _startVoice() async {
    final voice = VoiceMesh(
      myId: myId,
      iceServers: iceServers(),
      sendSignal: (peer, msg) => signaling?.sendDirect(peer, msg),
      onLinkState: _onLink,
    );
    mesh = voice;
    if (micGranted) micGranted = await voice.start();
    voice.setRemoteMuted(isDeafened);
    applyMic();
    await onVoiceReady();
  }

  void _onLink(String peerId, String state) {
    final peer = peers[peerId];
    if (peer == null) return;
    peer.link = state;
    notifyListeners();
  }

  void _enterRoom() {
    signaling?.joinRoom(settings.room.key);
    sendHello(reply: true);
    addSystem('You joined #$roomName'
        '${micGranted ? '' : ' (listen-only: mic not allowed)'}');
  }

  void sendHello({bool reply = false}) {
    signaling?.sendBroadcast({
      't': 'hello',
      'cs': settings.displayName,
      'cl': settings.colorIndex,
      'bx': boomboxState(),
      if (reply) 'r': true,
    });
  }

  void _startTimers() {
    _helloTimer = Timer.periodic(_helloEvery, (_) => sendHello());
    _pruneTimer = Timer.periodic(_pruneEvery, (_) => _prune());
  }

  void _prune() {
    final now = DateTime.now();
    final stale = peers.values
        .where((p) => now.difference(p.lastSeen) > Limits.peerTimeout)
        .map((p) => p.id)
        .toList();
    for (final id in stale) {
      peers.remove(id);
      mesh?.drop(id);
    }
    for (final p in peers.values) {
      final since = p.txSince;
      if (since != null && now.difference(since) > Limits.txTimeout) {
        p.transmitting = false;
        p.txSince = null;
      }
    }
    updateDuck();
    BackgroundService.update(_status());
    notifyListeners();
  }

  String _status() => '#$roomName · ${peers.length + 1} in voice';

  /// Move to the (already updated) room in `settings.room`.
  void switchRoom() {
    if (!joined) return;
    _switchTimer?.cancel();
    _switchTimer = Timer(_roomDebounce, _doSwitch);
  }

  void _doSwitch() {
    signaling?.sendBroadcast({'t': 'bye'});
    mesh?.dropAll();
    peers.clear();
    updateDuck();
    _enterRoom();
    BackgroundService.update(_status());
    notifyListeners();
  }

  Future<void> leave() async {
    if (!joined && !joining) return;
    _helloTimer?.cancel();
    _pruneTimer?.cancel();
    _switchTimer?.cancel();
    signaling?.sendBroadcast({'t': 'bye'});
    stopVoice();
    sfx.leaveChime();
    onVoiceStopped();
    await mesh?.dispose();
    await signaling?.dispose();
    mesh = null;
    signaling = null;
    peers.clear();
    joined = false;
    joining = false;
    net = NetState.offline;
    updateDuck();
    await BackgroundService.stop();
    notifyListeners();
  }
}

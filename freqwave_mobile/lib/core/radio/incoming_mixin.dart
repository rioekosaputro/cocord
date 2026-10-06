import '../models.dart';
import '../signaling.dart';
import 'boombox_mixin.dart';
import 'msg_utils.dart';
import 'radio_base.dart';
import '../synth.dart';

/// Handles every message arriving from other radios on the frequency.
/// All payloads are untrusted: each field is validated before use.
mixin IncomingMixin on RadioBase, BoomboxMixin {
  final Map<String, DateTime> _lastSound = {};

  @override
  void handleBroadcast(Json msg) {
    final m = msg;
    final id = m['id'] as String;
    switch (m['t']) {
      case 'hello':
        _onHello(id, m);
      case 'bye':
        _onBye(id);
      case 'chat':
        _onChat(id, m);
      case 'tx':
        _onTx(id, m);
      case 'snd':
        _onSound(id, m);
      case 'bx':
        applyRemoteBoombox(m);
    }
  }

  @override
  void handleDirect(Json msg) => mesh?.onSignal(msg['id'] as String, msg);

  String _name(Json m) =>
      MsgUtils.str(m['cs'], Limits.maxCallsign) ?? 'UNKNOWN';

  void _onHello(String id, Json m) {
    var peer = peers[id];
    final isNew = peer == null;
    if (isNew && peers.length >= Limits.maxPeers) return;
    peer = peers.putIfAbsent(id, () => Peer(id, _name(m)));
    peer.callsign = _name(m);
    peer.lastSeen = DateTime.now();
    if (MsgUtils.flag(m['r'])) signaling?.sendBroadcast(_helloMsg());
    _linkIfNeeded(peer);
    if (isNew) _announceJoin(peer, m);
    notifyListeners();
  }

  Json _helloMsg() =>
      {'t': 'hello', 'cs': settings.callsign, 'bx': boomboxState()};

  void _linkIfNeeded(Peer peer) {
    final voice = mesh;
    if (voice == null || voice.isLinked(peer.id)) return;
    if (!voice.isOfferer(peer.id)) return;
    peer.link = 'connecting';
    voice.connect(peer.id);
  }

  void _announceJoin(Peer peer, Json m) {
    addSystem('${peer.callsign} joined $freqLabel MHz');
    final bx = m['bx'];
    if (bx is Map) applyRemoteBoombox(Map<String, dynamic>.from(bx));
  }

  void _onBye(String id) {
    final peer = peers.remove(id);
    mesh?.drop(id);
    if (peer != null) addSystem('${peer.callsign} left the frequency');
    updateDuck();
    notifyListeners();
  }

  void _onChat(String id, Json m) {
    final text = MsgUtils.str(m['x'], Limits.maxChat);
    if (text == null) return;
    addMessage(ChatKind.remote, _name(m), text);
  }

  void _onTx(String id, Json m) {
    final peer = peers[id];
    if (peer == null) return;
    final on = MsgUtils.flag(m['on']);
    if (peer.transmitting == on) return;
    peer.transmitting = on;
    peer.txSince = on ? DateTime.now() : null;
    _remoteTone(on);
    updateDuck();
    notifyListeners();
  }

  void _remoteTone(bool on) {
    if (on) {
      if (settings.squelch) sfx.squelchKeyup();
      return;
    }
    if (settings.rogerBeep) sfx.rogerBeep();
    if (settings.squelch) {
      Future.delayed(const Duration(milliseconds: 150), sfx.squelchTail);
    }
  }

  void _onSound(String id, Json m) {
    final key = m['n'];
    if (!kSoundboard.any((s) => s.key == key)) return;
    final now = DateTime.now();
    final last = _lastSound[id];
    if (last != null && now.difference(last) < Limits.soundCooldown) return;
    _lastSound[id] = now;
    sfx.soundboard(key as String);
    addSystem('${_name(m)} dropped sound: ${key.toUpperCase()}');
  }
}

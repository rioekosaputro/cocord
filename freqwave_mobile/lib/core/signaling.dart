import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'models.dart';

typedef Json = Map<String, dynamic>;

/// Presence, chat and WebRTC signaling over an MQTT broker.
///
/// Topics (per room):
///   cocord/v1/<freq>/b            room broadcast (hello/bye/chat/tx/snd/bx)
///   cocord/v1/<freq>/s/<peerId>   direct WebRTC signaling to one peer
class Signaling {
  static const List<(String, int)> publicBrokers = [
    ('broker.emqx.io', 1883),
    ('broker.hivemq.com', 1883),
    ('test.mosquitto.org', 1883),
  ];

  final String myId;
  String brokerHost;
  int brokerPort;

  void Function(Json msg)? onBroadcast;
  void Function(Json msg)? onDirect;
  void Function(NetState state)? onState;
  void Function()? onReconnected;

  MqttServerClient? _client;
  StreamSubscription? _sub;
  String? _room; // current room key
  NetState _state = NetState.offline;
  bool _disposed = false;
  String connectedTo = '';

  Signaling(this.myId, {this.brokerHost = '', this.brokerPort = 1883});

  NetState get state => _state;

  void _setState(NetState s) {
    if (_state == s) return;
    _state = s;
    onState?.call(s);
  }

  List<(String, int)> get _brokerList => [
        if (brokerHost.trim().isNotEmpty) (brokerHost.trim(), brokerPort),
        ...publicBrokers,
      ];

  /// Connects to the first reachable broker. Returns false if all fail.
  Future<bool> connect() async {
    _setState(NetState.connecting);
    for (final (host, port) in _brokerList) {
      if (_disposed) return false;
      final c = MqttServerClient.withPort(host, 'fw$myId', port)
        ..logging(on: false)
        ..keepAlivePeriod = 20
        ..connectTimeoutPeriod = 6000
        ..autoReconnect = true
        ..resubscribeOnAutoReconnect = true
        ..onAutoReconnect = (() => _setState(NetState.connecting))
        ..onAutoReconnected = _handleReconnected
        ..onDisconnected = _handleDisconnected
        ..connectionMessage = MqttConnectMessage()
            .withClientIdentifier('fw$myId')
            .startClean();
      try {
        await c.connect();
      } catch (e) {
        debugPrint('[Signaling] $host:$port failed: $e');
        c.disconnect();
        continue;
      }
      if (c.connectionStatus?.state != MqttConnectionState.connected) {
        c.disconnect();
        continue;
      }
      _client = c;
      connectedTo = host;
      _sub = c.updates?.listen(_onMessages);
      _setState(NetState.online);
      return true;
    }
    _setState(NetState.offline);
    return false;
  }

  void _handleReconnected() {
    _setState(NetState.online);
    onReconnected?.call();
  }

  void _handleDisconnected() {
    if (_disposed) return;
    // With autoReconnect the client re-enters connecting by itself; if it
    // gives up we end up here with a disconnected status.
    if (_client?.connectionStatus?.state != MqttConnectionState.connecting) {
      _setState(NetState.offline);
    }
  }

  String _base(String room) => 'cocord/v1/$room';

  /// Enter a room (leaving the previous one).
  void joinRoom(String room) {
    final c = _client;
    if (c == null) return;
    leaveRoom();
    _room = room;
    c.subscribe('${_base(room)}/b', MqttQos.atMostOnce);
    c.subscribe('${_base(room)}/s/$myId', MqttQos.atMostOnce);
  }

  void leaveRoom() {
    final c = _client;
    final room = _room;
    if (c == null || room == null) return;
    if (c.connectionStatus?.state == MqttConnectionState.connected) {
      c.unsubscribe('${_base(room)}/b');
      c.unsubscribe('${_base(room)}/s/$myId');
    }
    _room = null;
  }

  void _publish(String topic, Json msg) {
    final c = _client;
    if (c == null ||
        c.connectionStatus?.state != MqttConnectionState.connected) {
      return;
    }
    final b = MqttClientPayloadBuilder()..addUTF8String(jsonEncode(msg));
    c.publishMessage(topic, MqttQos.atMostOnce, b.payload!);
  }

  void sendBroadcast(Json msg) {
    final room = _room;
    if (room == null) return;
    _publish('${_base(room)}/b', {...msg, 'id': myId});
  }

  void sendDirect(String peerId, Json msg) {
    final room = _room;
    if (room == null) return;
    _publish('${_base(room)}/s/$peerId', {...msg, 'id': myId});
  }

  void _onMessages(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final e in events) {
      final m = e.payload;
      if (m is! MqttPublishMessage) continue;
      final bytes = m.payload.message;
      if (bytes.length > 24 * 1024) continue; // ignore oversized junk
      Json? msg;
      try {
        final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: true));
        if (decoded is Map) msg = Map<String, dynamic>.from(decoded);
      } catch (_) {
        continue;
      }
      if (msg == null) continue;
      final from = msg['id'];
      if (from is! String || from.isEmpty || from == myId) continue;
      final topic = e.topic;
      if (_room == null || !topic.startsWith(_base(_room!))) continue;
      if (topic.endsWith('/b')) {
        onBroadcast?.call(msg);
      } else if (topic.endsWith('/s/$myId')) {
        onDirect?.call(msg);
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _sub?.cancel();
    final c = _client;
    _client = null;
    if (c != null) {
      c.autoReconnect = false;
      c.disconnect();
    }
    _setState(NetState.offline);
  }
}

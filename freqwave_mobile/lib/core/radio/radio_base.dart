import 'package:flutter/foundation.dart';

import '../models.dart';
import '../settings.dart';
import '../sfx.dart';
import '../signaling.dart';
import '../voice_mesh.dart';

/// Shared state of the radio. Behaviour lives in the mixins under `radio/`;
/// this class only holds data and the few hooks the mixins use to talk to
/// each other.
abstract class RadioBase extends ChangeNotifier {
  static const int _maxMessages = 300;

  AppSettings settings = AppSettings();
  final Sfx sfx = Sfx();
  final String myId = randomId();

  Signaling? signaling;
  VoiceMesh? mesh;

  final Map<String, Peer> peers = {};
  final List<ChatMessage> messages = [];

  NetState net = NetState.offline;
  bool joined = false;
  bool joining = false;
  bool micGranted = false;
  bool muted = false;
  bool transmitting = false;
  bool openMic = false;
  bool scanning = false;
  bool chatVisible = false;
  int unread = 0;
  String? error;

  /// Set by the UI to show short messages (snack bars).
  void Function(String message)? toast;

  // Hooks implemented by the mixins.
  void handleBroadcast(Json msg);
  void handleDirect(Json msg);
  Json boomboxState();
  void updateDuck();
  Future<void> onVoiceReady();
  void onVoiceStopped();

  bool get anyRemoteTx => peers.values.any((p) => p.transmitting);

  String get freqLabel => Freq.fmt(settings.frequency);

  void addMessage(ChatKind kind, String sender, String text) {
    messages.add(ChatMessage(kind, sender, text));
    if (messages.length > _maxMessages) messages.removeAt(0);
    if (kind != ChatKind.local && !chatVisible) unread++;
    notifyListeners();
  }

  void addSystem(String text) => addMessage(ChatKind.system, 'SYSTEM', text);

  List<Map<String, dynamic>> iceServers() => [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun.cloudflare.com:3478'},
        if (settings.turnUrl.trim().isNotEmpty)
          {
            'urls': settings.turnUrl.trim(),
            'username': settings.turnUser,
            'credential': settings.turnPass,
          },
      ];
}

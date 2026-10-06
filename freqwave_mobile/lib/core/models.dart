import 'dart:math';

import 'package:flutter/painting.dart';

class Station {
  final String name;
  final String desc;
  final String url;
  const Station(this.name, this.desc, this.url);
}

const List<Station> kStations = [
  Station('Nightride FM', 'Synthwave & Retrowave 24/7',
      'https://stream.nightride.fm/nightride.mp3'),
  Station('Chillsynth FM', 'Chill synth & lo-fi vibes',
      'https://stream.nightride.fm/chillsynth.mp3'),
  Station('Darksynth FM', 'Darksynth & cyber industrial',
      'https://stream.nightride.fm/darksynth.mp3'),
  Station('Spacesynth FM', 'Deep space ambient recon',
      'https://stream.nightride.fm/spacesynth.mp3'),
];

/// Avatar colors a member can pick; only the index travels over the network.
const List<Color> kMemberColors = [
  Color(0xFF3B82F6),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFFA855F7),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFF84CC16),
];

Color memberColor(int index) =>
    kMemberColors[index.clamp(0, kMemberColors.length - 1)];

class Peer {
  final String id;
  String name;
  int colorIndex;
  bool transmitting = false;
  DateTime? txSince;
  DateTime lastSeen = DateTime.now();

  /// Voice link state: new | connecting | connected | failed
  String link = 'new';

  Peer(this.id, this.name, this.colorIndex);
}

enum ChatKind { local, remote, system }

class ChatMessage {
  final ChatKind kind;
  final String sender;
  final int colorIndex;
  final String text;
  final DateTime time = DateTime.now();
  ChatMessage(this.kind, this.sender, this.text, [this.colorIndex = 0]);
}

enum NetState { offline, connecting, online }

/// Display name: printable text, collapsed spaces, at most [Limits.maxName].
String sanitizeName(String raw) {
  final clean = raw
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final cut = clean.length > Limits.maxName
      ? clean.substring(0, Limits.maxName).trim()
      : clean;
  return cut.isEmpty ? 'Guest' : cut;
}

String randomId() {
  final r = Random.secure();
  return List.generate(10, (_) => r.nextInt(36).toRadixString(36)).join();
}

/// Limits shared by networking code and tests.
class Limits {
  static const int maxChat = 500;
  static const int maxName = 20;
  static const int maxRoomName = 32;
  static const int maxPassword = 64;
  static const int maxPeers = 8;
  static const int maxRecents = 8;
  static const Duration peerTimeout = Duration(seconds: 30);
  static const Duration txTimeout = Duration(seconds: 90);
  static const Duration soundCooldown = Duration(milliseconds: 600);
}

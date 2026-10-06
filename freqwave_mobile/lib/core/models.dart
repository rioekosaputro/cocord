import 'dart:math';

/// Frequency helpers. A "frequency" is a virtual room (e.g. 144.800 MHz).
class Freq {
  static const double min = 88.0;
  static const double max = 999.0;
  static const double defaultFreq = 144.800;
  static const double step = 0.05;

  static double clamp(double f) =>
      double.parse(f.clamp(min, max).toStringAsFixed(3));

  static String fmt(double f) => f.toStringAsFixed(3);

  /// Topic-safe key, "144.800" -> "144_800".
  static String key(double f) => fmt(f).replaceAll('.', '_');
}

class FreqPreset {
  final String name;
  final double freq;
  const FreqPreset(this.name, this.freq);
}

const List<FreqPreset> kPresets = [
  FreqPreset('Squad Alpha', 144.800),
  FreqPreset('Squad Bravo', 433.920),
  FreqPreset('Command Net', 121.500),
  FreqPreset('Open Chatter', 446.000),
  FreqPreset('Night Watch', 98.500),
  FreqPreset('Recon', 104.200),
];

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

class Peer {
  final String id;
  String callsign;
  bool transmitting = false;
  DateTime? txSince;
  DateTime lastSeen = DateTime.now();

  /// Voice link state: new | connecting | connected | failed
  String link = 'new';

  Peer(this.id, this.callsign);
}

enum ChatKind { local, remote, system }

class ChatMessage {
  final ChatKind kind;
  final String sender;
  final String text;
  final DateTime time = DateTime.now();
  ChatMessage(this.kind, this.sender, this.text);
}

enum NetState { offline, connecting, online }

String sanitizeCallsign(String raw) {
  var s = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\- ]'), '').trim();
  if (s.length > 12) s = s.substring(0, 12).trim();
  return s.isEmpty ? 'BRAVO-06' : s;
}

String randomId() {
  final r = Random.secure();
  return List.generate(10, (_) => r.nextInt(36).toRadixString(36)).join();
}

/// Limits shared by networking code and tests.
class Limits {
  static const int maxChat = 500;
  static const int maxCallsign = 12;
  static const int maxPeers = 8;
  static const Duration peerTimeout = Duration(seconds: 30);
  static const Duration txTimeout = Duration(seconds: 90);
  static const Duration soundCooldown = Duration(milliseconds: 600);
}

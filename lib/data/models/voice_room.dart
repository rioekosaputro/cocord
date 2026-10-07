class VoiceRoom {
  final String id;
  final String name;
  final String description;
  final String hostCallsign;
  final int maxParticipants;
  final bool isSecureEncrypted;
  final DateTime createdAt;

  const VoiceRoom({
    required this.id,
    required this.name,
    this.description = '',
    required this.hostCallsign,
    this.maxParticipants = 32,
    this.isSecureEncrypted = true,
    required this.createdAt,
  });

  String get shareableUrl => 'https://cocord.app/join?room=$id';
  String get deepLinkUri => 'cocord://join?room=$id';
}

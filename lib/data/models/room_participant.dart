class RoomParticipant {
  final String id;
  final String callsign;
  final bool isSpeaking;
  final bool isMuted;
  final bool isDeafened;
  final bool isHost;
  final DateTime joinedAt;
  final int avatarColorIndex;

  RoomParticipant({
    required this.id,
    required this.callsign,
    this.isSpeaking = false,
    this.isMuted = false,
    this.isDeafened = false,
    this.isHost = false,
    required this.joinedAt,
    this.avatarColorIndex = 0,
  });

  RoomParticipant copyWith({
    String? id,
    String? callsign,
    bool? isSpeaking,
    bool? isMuted,
    bool? isDeafened,
    bool? isHost,
    DateTime? joinedAt,
    int? avatarColorIndex,
  }) {
    return RoomParticipant(
      id: id ?? this.id,
      callsign: callsign ?? this.callsign,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isMuted: isMuted ?? this.isMuted,
      isDeafened: isDeafened ?? this.isDeafened,
      isHost: isHost ?? this.isHost,
      joinedAt: joinedAt ?? this.joinedAt,
      avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
    );
  }
}

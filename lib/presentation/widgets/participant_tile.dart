import 'package:flutter/material.dart';
import '../../core/theme/tactical_theme.dart';
import '../../data/models/room_participant.dart';

class ParticipantTile extends StatelessWidget {
  final RoomParticipant participant;
  final bool isMe;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.isMe = false,
  });

  static const List<Color> _avatarColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
  ];

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColors[participant.avatarColorIndex % _avatarColors.length];
    final isSpeaking = participant.isSpeaking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSpeaking ? avatarColor.withOpacity(0.12) : TacticalTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSpeaking
              ? avatarColor
              : (isMe ? TacticalTheme.accentPrimary.withOpacity(0.4) : Colors.white10),
          width: isSpeaking ? 2.0 : 1.0,
        ),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: avatarColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar with Animated Speaking Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSpeaking)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: avatarColor.withOpacity(0.5), width: 2),
                        ),
                      ),
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: avatarColor,
                      child: Text(
                        participant.callsign.substring(0, participant.callsign.length >= 2 ? 2 : 1),
                        style: const TextStyle(
                          fontFamily: 'ChakraPetch',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Callsign Name
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      participant.callsign,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isMe)
                      const Text(
                        ' (You)',
                        style: TextStyle(
                          fontSize: 11,
                          color: TacticalTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Speaking / Standby status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSpeaking
                        ? TacticalTheme.accentGreen.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isSpeaking ? 'SPEAKING' : 'LISTENING',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isSpeaking ? TacticalTheme.accentGreen : TacticalTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top Badges (Host & Mute status)
          Positioned(
            top: 8,
            left: 8,
            child: participant.isHost
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: TacticalTheme.accentAmber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: TacticalTheme.accentAmber.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'HOST',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: TacticalTheme.accentAmber,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (participant.isMuted)
                  const Icon(Icons.mic_off_rounded, color: TacticalTheme.accentDanger, size: 16),
                if (participant.isDeafened) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.headset_off_rounded, color: TacticalTheme.accentDanger, size: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

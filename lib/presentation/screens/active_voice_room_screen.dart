import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/tactical_theme.dart';
import '../../core/voice/voice_room_manager.dart';
import '../widgets/participant_tile.dart';
import '../widgets/voice_dock.dart';
import '../widgets/rf_oscilloscope.dart';
import '../widgets/room_invite_sheet.dart';
import '../widgets/chat_sheet.dart';
import '../widgets/settings_dialog.dart';

class ActiveVoiceRoomScreen extends StatelessWidget {
  const ActiveVoiceRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceRoomManager>();
    final room = voice.currentRoom;
    final isDark = voice.isDarkMode;

    if (room == null) {
      return const Scaffold(
        body: Center(child: Text('No active room')),
      );
    }

    final participants = voice.participants;
    final activeProfile = voice.selectedVoiceProfile;

    return Scaffold(
      backgroundColor: isDark ? TacticalTheme.bgAppDark : TacticalTheme.bgAppLight,
      appBar: AppBar(
        backgroundColor: isDark ? TacticalTheme.bgPanelDark : TacticalTheme.bgPanelLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : TacticalTheme.textPrimaryLight),
          onPressed: () => voice.leaveRoom(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: voice.isMeshOnline ? TacticalTheme.accentGreen : TacticalTheme.accentAmber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    room.name,
                    style: TextStyle(
                      fontFamily: 'ChakraPetch',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : TacticalTheme.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'ID: ${room.id}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: TacticalTheme.accentAmber,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${participants.length} CONNECTED',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: isDark ? TacticalTheme.textSecondaryDark : TacticalTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Voice Changer Badge shortcut
          IconButton(
            icon: Icon(Icons.record_voice_over_rounded,
                color: activeProfile.id == 'natural' ? (isDark ? Colors.white70 : TacticalTheme.textSecondaryLight) : TacticalTheme.accentGreen),
            tooltip: 'Voice Profile: ${activeProfile.name}',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const SettingsDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: TacticalTheme.accentPrimary),
            tooltip: 'Invite Squad',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => RoomInviteSheet(room: room),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Audio Visualizer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: RFOscilloscope(isTransmitting: voice.isTransmitting),
            ),

            // Participants Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final p = participants[index];
                    return ParticipantTile(
                      participant: p,
                      isMe: p.callsign == voice.myCallsign,
                    );
                  },
                ),
              ),
            ),

            // Floating Bottom Voice Dock
            Padding(
              padding: const EdgeInsets.all(16),
              child: VoiceDock(
                onOpenChat: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const TacticalChatSheet(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

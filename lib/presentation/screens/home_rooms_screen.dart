import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/tactical_theme.dart';
import '../../core/voice/voice_room_manager.dart';
import '../widgets/create_room_dialog.dart';
import '../widgets/join_room_dialog.dart';
import '../widgets/settings_dialog.dart';
import 'active_voice_room_screen.dart';

class HomeRoomsScreen extends StatelessWidget {
  const HomeRoomsScreen({super.key});

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceRoomManager>();
    final isDark = voice.isDarkMode;

    // Jika pengguna sedang berada di dalam room, tampilkan ActiveVoiceRoomScreen
    if (voice.isInRoom) {
      return const ActiveVoiceRoomScreen();
    }

    final publicChannels = voice.publicChannels;
    final activeProfile = voice.selectedVoiceProfile;

    return Scaffold(
      backgroundColor: isDark ? TacticalTheme.bgAppDark : TacticalTheme.bgAppLight,
      appBar: AppBar(
        backgroundColor: isDark ? TacticalTheme.bgPanelDark : TacticalTheme.bgPanelLight,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: TacticalTheme.accentPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.record_voice_over_rounded, color: TacticalTheme.accentPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'COCORD',
              style: TextStyle(
                fontFamily: 'ChakraPetch',
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: isDark ? Colors.white : TacticalTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: TacticalTheme.accentAmber.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VOICE MESH',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: TacticalTheme.accentAmber,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? TacticalTheme.accentAmber : TacticalTheme.accentPrimary,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => voice.toggleTheme(),
          ),
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: isDark ? Colors.white : TacticalTheme.textPrimaryLight,
            ),
            tooltip: 'Settings & Voice Studio',
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Profile & Active Voice Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? TacticalTheme.bgCardDark : TacticalTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: TacticalTheme.accentPrimary,
                          child: Text(
                            voice.myCallsign.substring(0, voice.myCallsign.length >= 2 ? 2 : 1),
                            style: const TextStyle(
                              fontFamily: 'ChakraPetch',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                voice.myCallsign,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : TacticalTheme.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: TacticalTheme.accentGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'ONLINE // READY TO TRANSMIT',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      color: TacticalTheme.accentGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.settings_rounded,
                              color: isDark ? TacticalTheme.textSecondaryDark : TacticalTheme.textSecondaryLight, size: 20),
                          tooltip: 'Edit Profile & Settings',
                          onPressed: () => _showSettingsDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Active Voice Profile Banner
                    InkWell(
                      onTap: () => _showSettingsDialog(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: TacticalTheme.accentPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: TacticalTheme.accentPrimary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(activeProfile.icon, color: TacticalTheme.accentPrimary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'VOICE: ${activeProfile.name.toUpperCase()}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: TacticalTheme.accentPrimary,
                                    ),
                                  ),
                                  Text(
                                    activeProfile.description,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? TacticalTheme.textSecondaryDark : TacticalTheme.textSecondaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: TacticalTheme.accentPrimary, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons (Create & Join Room)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TacticalTheme.accentPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'CREATE ROOM',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const CreateRoomDialog(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TacticalTheme.accentGreen,
                        side: const BorderSide(color: TacticalTheme.accentGreen),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.link_rounded, size: 20),
                      label: const Text(
                        'JOIN VIA LINK',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const JoinRoomDialog(),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FEATURED VOICE CHANNELS',
                    style: TextStyle(
                      fontFamily: 'ChakraPetch',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark ? TacticalTheme.textSecondaryDark : TacticalTheme.textSecondaryLight,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: TacticalTheme.accentGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '3 CHANNELS LIVE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: TacticalTheme.accentGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Channel List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: publicChannels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ch = publicChannels[index];

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? TacticalTheme.bgCardDark : TacticalTheme.bgCardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: TacticalTheme.accentPrimary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.headset_mic_rounded,
                              color: TacticalTheme.accentPrimary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ch.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : TacticalTheme.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ch.id} • ${ch.description}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? TacticalTheme.textSecondaryDark : TacticalTheme.textSecondaryLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TacticalTheme.accentPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => voice.joinRoom(ch.id, roomName: ch.name),
                          child: const Text('CONNECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

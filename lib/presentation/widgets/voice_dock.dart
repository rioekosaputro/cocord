import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/tactical_theme.dart';
import '../../core/voice/voice_room_manager.dart';

class VoiceDock extends StatelessWidget {
  final VoidCallback onOpenChat;

  const VoiceDock({super.key, required this.onOpenChat});

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceRoomManager>();
    final isTransmitting = voice.isTransmitting;
    final isPttMode = voice.isPttMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TacticalTheme.bgPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Transmission Button
          GestureDetector(
            onTapDown: isPttMode
                ? (_) {
                    HapticFeedback.heavyImpact();
                    voice.startTransmitting();
                  }
                : null,
            onTapUp: isPttMode
                ? (_) {
                    HapticFeedback.mediumImpact();
                    voice.stopTransmitting();
                  }
                : null,
            onTapCancel: isPttMode ? () => voice.stopTransmitting() : null,
            onTap: !isPttMode
                ? () {
                    HapticFeedback.selectionClick();
                    voice.toggleMute();
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: isTransmitting
                      ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                      : [TacticalTheme.accentPrimary, const Color(0xFF2563EB)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isTransmitting ? TacticalTheme.accentDanger : TacticalTheme.accentPrimary)
                        .withOpacity(0.35),
                    blurRadius: 15,
                    spreadRadius: isTransmitting ? 2 : 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isTransmitting ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isTransmitting
                        ? 'TRANSMITTING VOICE (LIVE)'
                        : (isPttMode ? 'HOLD TO TRANSMIT (PTT)' : (voice.isMuted ? 'UNMUTE MIC' : 'OPEN MIC ACTIVE')),
                    style: const TextStyle(
                      fontFamily: 'ChakraPetch',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Secondary Controls Row (Mute, Deafen, Mode Toggle, Chat, Leave)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Mute Button
              _dockIconButton(
                icon: voice.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: voice.isMuted ? 'Muted' : 'Mute',
                isActive: voice.isMuted,
                activeColor: TacticalTheme.accentDanger,
                onTap: () => voice.toggleMute(),
              ),

              // Deafen Button
              _dockIconButton(
                icon: voice.isDeafened ? Icons.headset_off_rounded : Icons.headset_rounded,
                label: voice.isDeafened ? 'Deafened' : 'Deafen',
                isActive: voice.isDeafened,
                activeColor: TacticalTheme.accentDanger,
                onTap: () => voice.toggleDeafen(),
              ),

              // PTT / Open Mic Mode Toggle
              _dockIconButton(
                icon: isPttMode ? Icons.touch_app_rounded : Icons.graphic_eq_rounded,
                label: isPttMode ? 'PTT Mode' : 'Open Mic',
                isActive: !isPttMode,
                activeColor: TacticalTheme.accentGreen,
                onTap: () => voice.togglePttMode(),
              ),

              // Chat Sheet
              _dockIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                isActive: false,
                onTap: onOpenChat,
              ),

              // Leave Room Button
              _dockIconButton(
                icon: Icons.call_end_rounded,
                label: 'Leave',
                isActive: true,
                activeColor: TacticalTheme.accentDanger,
                onTap: () => voice.leaveRoom(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dockIconButton({
    required IconData icon,
    required String label,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = isActive ? (activeColor ?? TacticalTheme.accentPrimary) : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? (activeColor ?? TacticalTheme.accentPrimary).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: color,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

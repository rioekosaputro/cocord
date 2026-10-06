import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/radio/radio_controller.dart';
import '../theme.dart';
import 'device_picker.dart';

/// Call controls: mute mic, deafen, audio devices and leave.
class VoiceBar extends StatelessWidget {
  const VoiceBar({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    final ptt = r.settings.pttMode;
    return Panel(
      border: r.joined ? AppColors.green : AppColors.red,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _RoundButton(
            icon: r.micMuted ? Icons.mic_off : Icons.mic,
            label: ptt ? 'PTT MODE' : (r.micMuted ? 'UNMUTE' : 'MUTE'),
            active: r.micMuted,
            onTap: ptt ? null : r.toggleMicMute,
          ),
          _RoundButton(
            icon: r.isDeafened ? Icons.headset_off : Icons.headset,
            label: r.isDeafened ? 'UNDEAFEN' : 'DEAFEN',
            active: r.isDeafened,
            onTap: r.toggleDeafen,
          ),
          _RoundButton(
            icon: Icons.settings_voice,
            label: 'AUDIO',
            onTap: () => showDeviceSheet(context),
          ),
          _RoundButton(
            icon: r.joined ? Icons.call_end : Icons.call,
            label: r.joined ? 'LEAVE' : 'JOIN',
            color: r.joined ? AppColors.red : AppColors.green,
            onTap: r.joined ? r.leave : (r.joining ? null : r.join),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback? onTap;

  const _RoundButton({
    required this.icon,
    required this.label,
    this.active = false,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (active ? Colors.white : const Color(0xFF2A3550));
    final fg = color != null || !active ? Colors.white : Colors.black;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      IconButton.filled(
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          fixedSize: const Size(52, 52),
        ),
        icon: Icon(icon),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(
              fontFamily: kMono, fontSize: 9, color: AppColors.muted)),
    ]);
  }
}

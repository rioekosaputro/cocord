import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/radio/radio_controller.dart';
import '../theme.dart';
import '../widgets/boombox_card.dart';
import '../widgets/device_picker.dart';
import '../widgets/oscilloscope.dart';
import '../widgets/peers_card.dart';
import '../widgets/ptt_button.dart';
import '../widgets/room_header.dart';
import '../widgets/soundboard_grid.dart';

class RadioPage extends StatelessWidget {
  const RadioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _ConnectBanner(),
        RoomHeader(),
        SizedBox(height: 12),
        _Scope(),
        SizedBox(height: 12),
        PttButton(),
        _QuickToggles(),
        PeersCard(),
        SizedBox(height: 12),
        BoomboxCard(),
        SizedBox(height: 16),
        SectionLabel('SOUNDBOARD'),
        SoundboardGrid(),
        SizedBox(height: 16),
      ],
    );
  }
}

class _Scope extends StatelessWidget {
  const _Scope();

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    final mode = r.transmitting
        ? ScopeMode.transmitting
        : (r.anyRemoteTx ? ScopeMode.receiving : ScopeMode.idle);
    return Oscilloscope(mode: mode);
  }
}

class _QuickToggles extends StatelessWidget {
  const _QuickToggles();

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: FilterChip(
              avatar: const Icon(Icons.mic, size: 16),
              label: const Text('OPEN MIC'),
              selected: r.openMic,
              onSelected: r.setOpenMic,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilterChip(
              avatar: Icon(r.muted ? Icons.volume_off : Icons.volume_up,
                  size: 16),
              label: Text(r.muted ? 'MUTED' : 'MUTE'),
              selected: r.muted,
              onSelected: (_) => r.toggleMute(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ActionChip(
              avatar: const Icon(Icons.headset_mic, size: 16),
              label: const Text('AUDIO'),
              onPressed: () => showDeviceSheet(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when not connected (or when connecting failed).
class _ConnectBanner extends StatelessWidget {
  const _ConnectBanner();

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    if (r.joined) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        border: AppColors.red,
        child: Row(
          children: [
            Expanded(
              child: Text(
                r.joining
                    ? 'Connecting…'
                    : (r.error ?? 'You are not connected.'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (!r.joining)
              FilledButton(onPressed: r.join, child: const Text('CONNECT')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/radio/radio_controller.dart';
import '../theme.dart';
import '../widgets/boombox_card.dart';
import '../widgets/voice_bar.dart';
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
        PeersCard(),
        SizedBox(height: 12),
        _PttSection(),
        VoiceBar(),
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

/// Big hold-to-talk button, only in push-to-talk mode.
class _PttSection extends StatelessWidget {
  const _PttSection();

  @override
  Widget build(BuildContext context) {
    final ptt = context.select<RadioController, bool>((r) => r.settings.pttMode);
    if (!ptt) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: PttButton(),
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

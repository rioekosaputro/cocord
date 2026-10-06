import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/radio/radio_controller.dart';
import '../theme.dart';

/// Synced internet-radio boombox with station switching and ducking.
class BoomboxCard extends StatelessWidget {
  const BoomboxCard({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    return Panel(
      border: AppColors.amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(r),
          const SizedBox(height: 8),
          _Transport(r),
          if (r.boomError != null)
            Text(r.boomError!,
                style: const TextStyle(fontSize: 12, color: AppColors.red)),
          _VolumeRow(r),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final RadioController r;
  const _Header(this.r);

  @override
  Widget build(BuildContext context) {
    final ducking = r.transmitting || r.anyRemoteTx;
    return Row(
      children: [
        const Icon(Icons.speaker, color: AppColors.amber, size: 18),
        const SizedBox(width: 6),
        const Text('SYNCED BOOMBOX',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.amber)),
        const Spacer(),
        Text(ducking ? 'DUCKING' : 'AUTO-DUCK ARMED',
            style: TextStyle(
                fontFamily: kMono,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: ducking ? AppColors.amber : AppColors.green)),
      ],
    );
  }
}

class _Transport extends StatelessWidget {
  final RadioController r;
  const _Transport(this.r);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
            onPressed: () => r.nextStation(-1),
            icon: const Icon(Icons.skip_previous)),
        _PlayButton(r),
        IconButton(
            onPressed: () => r.nextStation(1),
            icon: const Icon(Icons.skip_next)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(r.station.desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: kMono, fontSize: 10, color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final RadioController r;
  const _PlayButton(this.r);

  @override
  Widget build(BuildContext context) {
    if (r.buffering && r.playing) {
      return const SizedBox(
          width: 48,
          height: 48,
          child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 3)));
    }
    return IconButton(
      onPressed: r.togglePlay,
      iconSize: 40,
      color: AppColors.blue,
      icon: Icon(r.playing ? Icons.pause_circle_filled : Icons.play_circle_fill),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final RadioController r;
  const _VolumeRow(this.r);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.volume_down, size: 18, color: AppColors.muted),
        Expanded(
          child: Slider(
            value: r.settings.boomboxVolume,
            onChanged: r.setBoomboxVolume,
            onChangeEnd: (_) => r.commitBoomboxVolume(),
          ),
        ),
        const Icon(Icons.volume_up, size: 18, color: AppColors.muted),
      ],
    );
  }
}

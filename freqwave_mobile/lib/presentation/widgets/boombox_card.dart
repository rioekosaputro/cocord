import 'package:flutter/material.dart';
import '../../core/theme/tactical_theme.dart';

class BoomboxCard extends StatelessWidget {
  final bool isPlaying;
  final double volume;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onVolumeChanged;

  const BoomboxCard({
    super.key,
    required this.isPlaying,
    required this.volume,
    required this.onTogglePlay,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TacticalTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TacticalTheme.accentAmber.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.radio, color: TacticalTheme.accentAmber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'SYNCED BOOMBOX',
                    style: TextStyle(
                      fontFamily: 'ChakraPetch',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: TacticalTheme.accentAmber,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: TacticalTheme.accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AUTO-DUCK ON',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: TacticalTheme.accentGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: onTogglePlay,
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: TacticalTheme.accentCyan,
                  size: 38,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nightride FM // 24/7 Synthwave',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Synced across frequency listeners',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: TacticalTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: TacticalTheme.accentAmber,
              thumbColor: TacticalTheme.accentAmber,
              inactiveTrackColor: Colors.white12,
            ),
            child: Slider(
              value: volume,
              min: 0.0,
              max: 1.0,
              onChanged: onVolumeChanged,
            ),
          ),
        ],
      ),
    );
  }
}

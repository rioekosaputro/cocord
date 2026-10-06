import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/radio/radio_controller.dart';
import '../theme.dart';

/// Everyone on the frequency, with live TX and voice-link indicators.
class PeersCard extends StatelessWidget {
  const PeersCard({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    final peers = r.peers.values.toList();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('ON FREQUENCY (${peers.length + 1})'),
          _PeerRow(
              name: '${r.settings.callsign} (you)',
              talking: r.transmitting,
              link: 'connected'),
          for (final p in peers)
            _PeerRow(name: p.callsign, talking: p.transmitting, link: p.link),
          if (peers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('No one else here yet. Share your frequency!',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}

class _PeerRow extends StatelessWidget {
  final String name;
  final bool talking;
  final String link;
  const _PeerRow(
      {required this.name, required this.talking, required this.link});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(talking ? Icons.graphic_eq : Icons.person_outline,
              size: 18, color: talking ? AppColors.red : AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    fontWeight: talking ? FontWeight.bold : FontWeight.normal)),
          ),
          Text(talking ? 'TX' : _linkLabel(link),
              style: TextStyle(
                  fontFamily: kMono,
                  fontSize: 10,
                  color: talking ? AppColors.red : _linkColor(link))),
        ],
      ),
    );
  }

  String _linkLabel(String l) => switch (l) {
        'connected' => 'VOICE OK',
        'failed' => 'RETRYING',
        _ => 'LINKING',
      };

  Color _linkColor(String l) => switch (l) {
        'connected' => AppColors.green,
        'failed' => AppColors.red,
        _ => AppColors.amber,
      };
}

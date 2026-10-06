import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/radio/radio_controller.dart';
import '../theme.dart';

/// Everyone in the room, with live talking and voice-link indicators.
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
          SectionLabel('IN THIS ROOM (${peers.length + 1})'),
          _MemberRow(
            name: '${r.settings.displayName} (you)',
            color: r.settings.colorIndex,
            talking: r.transmitting,
            link: 'connected',
          ),
          for (final p in peers)
            _MemberRow(
                name: p.name,
                color: p.colorIndex,
                talking: p.transmitting,
                link: p.link),
          if (peers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Nobody else is here yet. Tap INVITE!',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final String name;
  final int color;
  final bool talking;
  final String link;
  const _MemberRow({
    required this.name,
    required this.color,
    required this.talking,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _Avatar(name: name, color: memberColor(color), talking: talking),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: talking ? FontWeight.bold : FontWeight.normal)),
          ),
          Text(talking ? 'SPEAKING' : _linkLabel(link),
              style: TextStyle(
                  fontFamily: kMono,
                  fontSize: 10,
                  color: talking ? AppColors.green : _linkColor(link))),
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
        'connected' => AppColors.muted,
        'failed' => AppColors.red,
        _ => AppColors.amber,
      };
}

/// Round initial avatar; glows green while the member is speaking.
class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final bool talking;
  const _Avatar(
      {required this.name, required this.color, required this.talking});

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
            color: talking ? AppColors.green : Colors.transparent, width: 3),
      ),
      child: Text(initial,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}

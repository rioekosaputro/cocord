import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/radio/radio_controller.dart';
import '../theme.dart';

/// App bar title: brand + live connection state.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    final (label, color) = _status(r);
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 8),
        const Text(
          'FREQWAVE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        const Spacer(),
        Text(
          label,
          style: TextStyle(fontFamily: kMono, fontSize: 10, color: color),
        ),
      ],
    );
  }

  (String, Color) _status(RadioController r) {
    if (r.joining || r.net == NetState.connecting) {
      return ('CONNECTING…', AppColors.amber);
    }
    if (!r.joined) return ('OFFLINE', AppColors.red);
    final n = r.peers.length;
    return ('ON AIR · $n PEER${n == 1 ? '' : 'S'}', AppColors.green);
  }
}

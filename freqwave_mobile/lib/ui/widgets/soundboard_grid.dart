import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/radio/radio_controller.dart';
import '../../core/synth.dart';
import '../theme.dart';

/// Tactical soundboard: tap to play locally and drop it on the frequency.
class SoundboardGrid extends StatelessWidget {
  const SoundboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.read<RadioController>();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        for (final s in kSoundboard)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.card,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            onPressed: () => r.dropSound(s.key),
            child: Text(s.label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

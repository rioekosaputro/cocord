import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/radio/radio_controller.dart';
import '../theme.dart';

/// Step buttons, fine-tune slider, presets and scanner.
class TunerPanel extends StatelessWidget {
  const TunerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    return Column(
      children: [
        Row(children: [
          _StepButton('− ${Freq.step} MHz', () => r.step(-Freq.step)),
          const SizedBox(width: 8),
          _StepButton('+ ${Freq.step} MHz', () => r.step(Freq.step)),
        ]),
        Slider(
          value: r.settings.frequency.clamp(Freq.min, 500.0),
          min: Freq.min,
          max: 500,
          onChanged: (v) => r.tune(v),
        ),
        _Presets(r),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StepButton(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
        child: OutlinedButton(onPressed: onTap, child: Text(label)),
      );
}

class _Presets extends StatelessWidget {
  final RadioController r;
  const _Presets(this.r);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final p in kPresets)
          ChoiceChip(
            label: Text(p.name, style: const TextStyle(fontSize: 11)),
            selected: (r.settings.frequency - p.freq).abs() < 0.001,
            onSelected: (_) => r.tune(p.freq),
          ),
        ActionChip(
          avatar: Icon(r.scanning ? Icons.stop : Icons.radar, size: 16),
          label: Text(r.scanning ? 'SCANNING…' : 'SCAN',
              style: const TextStyle(fontSize: 11)),
          backgroundColor: r.scanning ? AppColors.amber : null,
          onPressed: r.toggleScan,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/radio/radio_controller.dart';
import '../theme.dart';

/// Big frequency read-out. Tap to type an exact frequency.
class FreqDisplay extends StatelessWidget {
  const FreqDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _askFrequency(context, r),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF070B10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blue.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const SectionLabel('TUNED FREQUENCY · TAP TO EDIT',
                color: AppColors.blue),
            _Value(r.freqLabel),
            Text(
              'CALLSIGN: ${r.settings.callsign}',
              style: const TextStyle(
                  fontFamily: kMono, fontSize: 10, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _askFrequency(BuildContext context, RadioController r) async {
    final ctl = TextEditingController(text: r.freqLabel);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tune frequency (MHz)'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              helperText: '${Freq.min.toInt()} – ${Freq.max.toInt()} MHz'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctl.text),
              child: const Text('Tune')),
        ],
      ),
    );
    if (text != null && !r.tuneText(text)) {
      r.toast?.call('Enter a frequency between 88 and 999 MHz');
    }
  }
}

class _Value extends StatelessWidget {
  final String value;
  const _Value(this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value,
            style: const TextStyle(
                fontFamily: kMono, fontSize: 38, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        const Text('MHz',
            style: TextStyle(
                fontFamily: kMono,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.amber)),
      ],
    );
  }
}

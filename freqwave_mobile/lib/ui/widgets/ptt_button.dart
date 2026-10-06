import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/radio/radio_controller.dart';
import '../theme.dart';

/// Hold-to-talk button. Uses raw pointer events so a finger drifting off the
/// button doesn't cancel the transmission early.
class PttButton extends StatelessWidget {
  const PttButton({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    final active = r.pttHeld;
    return Listener(
      onPointerDown: (_) => r.startTransmit(),
      onPointerUp: (_) => r.stopTransmit(),
      onPointerCancel: (_) => r.stopTransmit(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 110,
        decoration: _decoration(active),
        child: _Label(active: active),
      ),
    );
  }

  BoxDecoration _decoration(bool active) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: active
            ? const [Color(0xFFB81D43), AppColors.red]
            : const [Color(0xFF1B2433), Color(0xFF0F1520)],
      ),
      border: Border.all(
          color: active ? Colors.white : AppColors.blue,
          width: active ? 2.5 : 1.5),
      boxShadow: [
        BoxShadow(
          color: (active ? AppColors.red : AppColors.blue)
              .withValues(alpha: active ? 0.5 : 0.2),
          blurRadius: active ? 25 : 10,
          spreadRadius: active ? 3 : 0,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final bool active;
  const _Label({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : AppColors.blue;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.mic_none_rounded, size: 40, color: color),
        const SizedBox(height: 6),
        Text(
          active ? 'TALKING…' : 'HOLD TO TALK',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: color),
        ),
        Text(
          'OR USE THE VOLUME-DOWN KEY',
          style: TextStyle(
              fontFamily: kMono,
              fontSize: 9,
              color: active ? Colors.white70 : AppColors.muted),
        ),
      ],
    );
  }
}

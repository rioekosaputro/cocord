import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/tactical_theme.dart';

class PttTacticalButton extends StatefulWidget {
  final bool isTransmitting;
  final VoidCallback onTransmittingStart;
  final VoidCallback onTransmittingEnd;

  const PttTacticalButton({
    super.key,
    required this.isTransmitting,
    required this.onTransmittingStart,
    required this.onTransmittingEnd,
  });

  @override
  State<PttTacticalButton> createState() => _PttTacticalButtonState();
}

class _PttTacticalButtonState extends State<PttTacticalButton> {
  @override
  Widget build(BuildContext context) {
    final active = widget.isTransmitting;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.heavyImpact();
        widget.onTransmittingStart();
      },
      onTapUp: (_) {
        HapticFeedback.mediumImpact();
        widget.onTransmittingEnd();
      },
      onTapCancel: () {
        widget.onTransmittingEnd();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? [const Color(0xFFB81D43), TacticalTheme.accentRed]
                : [const Color(0xFF1B2433), const Color(0xFF0F1520)],
          ),
          border: Border.all(
            color: active ? Colors.white : TacticalTheme.accentCyan,
            width: active ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? TacticalTheme.accentRed.withOpacity(0.5)
                  : TacticalTheme.accentCyan.withOpacity(0.2),
              blurRadius: active ? 25 : 10,
              spreadRadius: active ? 3 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_none_rounded,
              size: 40,
              color: active ? Colors.white : TacticalTheme.accentCyan,
            ),
            const SizedBox(height: 6),
            Text(
              active ? 'TRANSMITTING // BROADCAST' : 'HOLD TO TRANSMIT (PTT)',
              style: TextStyle(
                fontFamily: 'ChakraPetch',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: active ? Colors.white : TacticalTheme.accentCyan,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'OR USE HARDWARE VOLUME DOWN KEY',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: active ? Colors.white70 : TacticalTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

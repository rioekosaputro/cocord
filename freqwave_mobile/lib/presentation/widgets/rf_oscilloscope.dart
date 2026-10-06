import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/tactical_theme.dart';

class RFOscilloscope extends StatefulWidget {
  final bool isTransmitting;

  const RFOscilloscope({super.key, required this.isTransmitting});

  @override
  State<RFOscilloscope> createState() => _RFOscilloscopeState();
}

class _RFOscilloscopeState extends State<RFOscilloscope>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF04070A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isTransmitting
                  ? TacticalTheme.accentRed
                  : TacticalTheme.accentCyan.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isTransmitting
                    ? TacticalTheme.accentRed.withOpacity(0.2)
                    : TacticalTheme.accentCyan.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Reticle Grid
                CustomPaint(
                  size: Size.infinite,
                  painter: ReticleGridPainter(),
                ),
                // Live Waveform
                CustomPaint(
                  size: Size.infinite,
                  painter: ScopeWavePainter(
                    phase: _controller.value * 2 * pi,
                    isTransmitting: widget.isTransmitting,
                  ),
                ),
                // Status Badges
                Positioned(
                  top: 6,
                  left: 8,
                  child: Text(
                    'RF OSCILLOSCOPE // 300-3400Hz DSP',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: TacticalTheme.accentCyan.withOpacity(0.8),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.isTransmitting
                          ? TacticalTheme.accentRed
                          : TacticalTheme.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.isTransmitting ? 'TX BROADCAST' : 'RX STANDBY',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: widget.isTransmitting ? Colors.white : TacticalTheme.accentGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ScopeWavePainter extends CustomPainter {
  final double phase;
  final bool isTransmitting;

  ScopeWavePainter({required this.phase, required this.isTransmitting});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isTransmitting ? TacticalTheme.accentRed : TacticalTheme.accentCyan
      ..strokeWidth = isTransmitting ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final midY = size.height / 2;
    final amplitude = isTransmitting ? 32.0 : 8.0;

    path.moveTo(0, midY);

    for (double x = 0; x <= size.width; x += 3) {
      final normalizedX = x / size.width;
      final y = midY +
          sin(normalizedX * 10 * pi + phase) * amplitude * sin(normalizedX * pi) +
          (isTransmitting ? (Random(x.toInt()).nextDouble() * 8 - 4) : 0);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ScopeWavePainter oldDelegate) => true;
}

class ReticleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(0.06)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

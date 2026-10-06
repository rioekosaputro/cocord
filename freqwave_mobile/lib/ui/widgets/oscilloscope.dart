import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

enum ScopeMode { idle, receiving, transmitting }

/// Animated RF scope: flat when idle, strong when someone is on air.
class Oscilloscope extends StatefulWidget {
  final ScopeMode mode;
  const Oscilloscope({super.key, required this.mode});

  @override
  State<Oscilloscope> createState() => _OscilloscopeState();
}

class _OscilloscopeState extends State<Oscilloscope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.mode) {
        ScopeMode.transmitting => AppColors.red,
        ScopeMode.receiving => AppColors.green,
        ScopeMode.idle => AppColors.blue,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF04070A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _WavePainter(_c.value * 2 * pi, widget.mode, _color),
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double phase;
  final ScopeMode mode;
  final Color color;
  _WavePainter(this.phase, this.mode, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = AppColors.blue.withValues(alpha: 0.07);
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.drawPath(_wave(size), Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = mode == ScopeMode.idle ? 1.5 : 2.5);
  }

  Path _wave(Size size) {
    final amp = mode == ScopeMode.idle ? 4.0 : 26.0;
    final mid = size.height / 2;
    final path = Path()..moveTo(0, mid);
    for (double x = 0; x <= size.width; x += 3) {
      final t = x / size.width;
      path.lineTo(x, mid + sin(t * 10 * pi + phase) * amp * sin(t * pi));
    }
    return path;
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.phase != phase || old.mode != mode;
}

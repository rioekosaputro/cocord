import 'dart:math';
import 'dart:typed_data';

/// Procedural radio sound effects rendered to 16-bit mono PCM WAV bytes.
/// Mirrors the Web Audio synthesis in the original web app.
class Synth {
  static const int sr = 22050;
  static final Random _rnd = Random(7);

  static Float64List _buf(double seconds) =>
      Float64List((seconds * sr).round());

  static Uint8List _wav(Float64List samples, {double gain = 1.0}) {
    final n = samples.length;
    final data = ByteData(44 + n * 2);
    void str(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sr, Endian.little);
    data.setUint32(28, sr * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (var i = 0; i < n; i++) {
      final v = (samples[i] * gain).clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  /// Exponential decay from [start] to 0.001 over [durN] samples.
  static double _env(int i, int durN, double start) {
    if (i < 0 || i >= durN) return 0;
    return start * pow(0.001 / start, i / durN);
  }

  static double _saw(double phase) => 2 * (phase - phase.floorToDouble()) - 1;
  static double _tri(double phase) =>
      4 * ((phase - phase.floorToDouble()) - 0.5).abs() - 1;
  static double _sine(double p) => sin(2 * pi * p);

  static void _tone(Float64List out, double t0, double dur, double freq,
      double amp, double Function(double) wave) {
    final s = (t0 * sr).round();
    final n = (dur * sr).round();
    for (var i = 0; i < n && s + i < out.length; i++) {
      out[s + i] += wave(freq * i / sr) * _env(i, n, amp);
    }
  }

  /// Band-pass biquad (RBJ cookbook), applied in place.
  static void _bandpass(Float64List x, double f0, double q) {
    final w0 = 2 * pi * f0 / sr;
    final alpha = sin(w0) / (2 * q);
    final b0 = alpha, b2 = -alpha;
    final a0 = 1 + alpha, a1 = -2 * cos(w0), a2 = 1 - alpha;
    double x1 = 0, x2 = 0, y1 = 0, y2 = 0;
    for (var i = 0; i < x.length; i++) {
      final y = (b0 * x[i] + b2 * x2 - a1 * y1 - a2 * y2) / a0;
      x2 = x1;
      x1 = x[i];
      y2 = y1;
      y1 = y;
      x[i] = y;
    }
  }

  static Float64List _noise(int n) {
    final o = Float64List(n);
    for (var i = 0; i < n; i++) {
      o[i] = _rnd.nextDouble() * 2 - 1;
    }
    return o;
  }

  // ---- Effects -----------------------------------------------------------

  /// Carrier key-up (short) / tail (longer) squelch burst.
  static Uint8List squelch({required bool keyup}) {
    final dur = keyup ? 0.04 : 0.09;
    final n = (dur * sr).round();
    final x = _noise(n);
    _bandpass(x, keyup ? 1800 : 2200, 2.0);
    for (var i = 0; i < n; i++) {
      x[i] *= 3.0 * _env(i, n, 0.35);
    }
    return _wav(x);
  }

  static Uint8List rogerBeep() {
    final o = _buf(0.2);
    _tone(o, 0.0, 0.07, 1200, 0.5, _sine);
    _tone(o, 0.075, 0.085, 950, 0.55, _sine);
    return _wav(o);
  }

  static Uint8List airhorn() {
    final o = _buf(0.75);
    const f = [466.16, 466.16, 622.25, 740.0, 932.33];
    for (var k = 0; k < f.length; k++) {
      _tone(o, 0, 0.7, f[k] + k * 2, 0.3, _saw);
    }
    return _wav(o, gain: 0.6);
  }

  static Uint8List siren() {
    final o = _buf(1.35);
    var phase = 0.0;
    final n = (1.3 * sr).round();
    for (var i = 0; i < n; i++) {
      final t = i / sr;
      final c = (t % 0.6) / 0.6;
      final f = 500 + 600 * (c < 0.5 ? c * 2 : (1 - c) * 2);
      phase += f / sr;
      o[i] = _saw(phase) * _env(i, n, 0.4);
    }
    return _wav(o, gain: 0.7);
  }

  static Uint8List morseSos() {
    final o = _buf(1.7);
    const pat = [
      [0.0, 0.08], [0.12, 0.08], [0.24, 0.08],
      [0.40, 0.22], [0.68, 0.22], [0.96, 0.22],
      [1.24, 0.08], [1.36, 0.08], [1.48, 0.08],
    ];
    for (final p in pat) {
      _tone(o, p[0], p[1], 800, 0.5, _sine);
    }
    return _wav(o);
  }

  static Uint8List targetLocked() {
    final o = _buf(0.4);
    final n = (0.35 * sr).round();
    var phase = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / sr;
      final f = t < 0.15 ? 1800 * pow(3200 / 1800, t / 0.15) : 3200.0;
      phase += f / sr;
      o[i] = _tri(phase) * _env(i, n, 0.45);
    }
    return _wav(o);
  }

  static Uint8List glitch() {
    final n = (0.3 * sr).round();
    final o = Float64List(n);
    for (var i = 0; i < n; i++) {
      o[i] = (_rnd.nextDouble() * 2 - 1) *
          (i % 20 < 10 ? 1 : -0.5) *
          _env(i, n, 0.5);
    }
    return _wav(o);
  }

  /// Two seconds of band-passed hiss, faded at both ends so it loops cleanly.
  static Uint8List staticLoop() {
    const n = 2 * sr;
    final x = _noise(n);
    _bandpass(x, 1200, 1.5);
    const fade = 800;
    for (var i = 0; i < fade; i++) {
      final g = i / fade;
      x[i] *= g;
      x[n - 1 - i] *= g;
    }
    return _wav(x, gain: 4.0);
  }
}

/// Soundboard entries: key, label, builder.
class SoundDef {
  final String key;
  final String label;
  final Uint8List Function() build;
  const SoundDef(this.key, this.label, this.build);
}

const List<SoundDef> kSoundboard = [
  SoundDef('roger', 'Roger That', Synth.rogerBeep),
  SoundDef('airhorn', 'Airhorn', Synth.airhorn),
  SoundDef('siren', 'Siren', Synth.siren),
  SoundDef('morse', 'Morse SOS', Synth.morseSos),
  SoundDef('target', 'Locked', Synth.targetLocked),
  SoundDef('glitch', 'Glitch', Synth.glitch),
];

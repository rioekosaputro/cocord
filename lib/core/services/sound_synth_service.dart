import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Procedural Tactical Sound Effects Generator
/// Synthesizes authentic radio SFX (Roger Beep, Squelch Bursts, Soundboard Drops)
/// directly into memory as standard PCM WAV format without needing external asset files.
class SoundSynthService {
  final AudioPlayer _sfxPlayer = AudioPlayer();

  Future<void> dispose() async {
    await _sfxPlayer.dispose();
  }

  /// Synthesize and play authentic dual-tone Roger Beep (1200Hz + 950Hz)
  Future<void> playRogerBeep() async {
    try {
      final wavBytes = _generateRogerBeepWav();
      final uri = Uri.dataFromBytes(wavBytes, mimeType: 'audio/wav');
      await _sfxPlayer.setAudioSource(AudioSource.uri(uri));
      await _sfxPlayer.play();
    } catch (e) {
      debugPrint('[SoundSynth] Error playing Roger Beep: $e');
    }
  }

  /// Synthesize and play atmospheric Squelch Burst noise
  Future<void> playSquelchBurst({bool isKeyup = false}) async {
    try {
      final wavBytes = _generateSquelchWav(isKeyup: isKeyup);
      final uri = Uri.dataFromBytes(wavBytes, mimeType: 'audio/wav');
      await _sfxPlayer.setAudioSource(AudioSource.uri(uri));
      await _sfxPlayer.play();
    } catch (e) {
      debugPrint('[SoundSynth] Error playing Squelch: $e');
    }
  }

  /// Play tactical soundboard effects
  Future<void> playSoundboardDrop(String soundKey) async {
    try {
      Uint8List? wavBytes;
      switch (soundKey) {
        case 'roger':
          await playRogerBeep();
          return;
        case 'airhorn':
          wavBytes = _generateAirhornWav();
          break;
        case 'siren':
          wavBytes = _generateSirenWav();
          break;
        case 'morse':
          wavBytes = _generateMorseWav();
          break;
        case 'target':
          wavBytes = _generateTargetLockWav();
          break;
        case 'glitch':
          wavBytes = _generateGlitchWav();
          break;
      }

      if (wavBytes != null) {
        final uri = Uri.dataFromBytes(wavBytes, mimeType: 'audio/wav');
        await _sfxPlayer.setAudioSource(AudioSource.uri(uri));
        await _sfxPlayer.play();
      }
    } catch (e) {
      debugPrint('[SoundSynth] Error playing sound drop: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // WAV SYNTHESIS IMPLEMENTATIONS
  // ---------------------------------------------------------------------------

  Uint8List _generateRogerBeepWav() {
    const sampleRate = 22050;
    const durTone1 = 0.07; // 70ms
    const durTone2 = 0.08; // 80ms
    const totalSamples = (sampleRate * (durTone1 + durTone2));
    final pcm = Int16List(totalSamples.toInt());

    final n1 = (sampleRate * durTone1).toInt();
    for (int i = 0; i < n1; i++) {
      final t = i / sampleRate;
      final env = 1.0 - (i / n1) * 0.3; // subtle decay
      final s = sin(2 * pi * 1200 * t) * env;
      pcm[i] = (s * 24000).clamp(-32768, 32767).toInt();
    }

    final n2 = (sampleRate * durTone2).toInt();
    for (int i = 0; i < n2; i++) {
      final t = i / sampleRate;
      final env = 1.0 - (i / n2) * 0.7; // exponential falloff
      final s = sin(2 * pi * 950 * t) * env;
      pcm[n1 + i] = (s * 26000).clamp(-32768, 32767).toInt();
    }

    return _createWavContainer(pcm, sampleRate: sampleRate);
  }

  Uint8List _generateSquelchWav({required bool isKeyup}) {
    const sampleRate = 22050;
    final duration = isKeyup ? 0.045 : 0.085;
    final totalSamples = (sampleRate * duration).toInt();
    final pcm = Int16List(totalSamples);
    final rand = Random();

    for (int i = 0; i < totalSamples; i++) {
      final env = isKeyup
          ? (1.0 - (i / totalSamples))
          : (sin((i / totalSamples) * pi)); // smooth bell envelope
      final noise = (rand.nextDouble() * 2 - 1) * env;
      pcm[i] = (noise * 18000).clamp(-32768, 32767).toInt();
    }

    return _createWavContainer(pcm, sampleRate: sampleRate);
  }

  Uint8List _generateAirhornWav() {
    const sampleRate = 22050;
    const duration = 0.65;
    final totalSamples = (sampleRate * duration).toInt();
    final pcm = Int16List(totalSamples);
    final freqs = [466.16, 622.25, 740.0, 932.33]; // Major chord

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = (1.0 - (i / totalSamples));
      double val = 0;
      for (final f in freqs) {
        val += sin(2 * pi * f * t);
      }
      val = (val / freqs.length) * env;
      pcm[i] = (val * 28000).clamp(-32768, 32767).toInt();
    }

    return _createWavContainer(pcm, sampleRate: sampleRate);
  }

  Uint8List _generateSirenWav() {
    const sampleRate = 22050;
    const duration = 0.9;
    final totalSamples = (sampleRate * duration).toInt();
    final pcm = Int16List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final freqMod = 550 + 450 * sin(2 * pi * 3.5 * t);
      final s = sin(2 * pi * freqMod * t);
      pcm[i] = (s * 25000).clamp(-32768, 32767).toInt();
    }

    return _createWavContainer(pcm, sampleRate: sampleRate);
  }

  Uint8List _generateMorseWav() {
    const sampleRate = 22050;
    const duration = 0.8;
    final totalSamples = (sampleRate * duration).toInt();
    final pcm = Int16List(totalSamples);

    // Beep SOS (... --- ...)
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final isBeep = (t >= 0.05 && t <= 0.15) ||
          (t >= 0.22 && t <= 0.32) ||
          (t >= 0.40 && t <= 0.60);
      if (isBeep) {
        final s = sin(2 * pi * 850 * t);
        pcm[i] = (s * 24000).clamp(-32768, 32767).toInt();
      } else {
        pcm[i] = 0;
      }
    }

    return _createWavContainer(pcm, sampleRate: sampleRate);
  }

  Uint8List _generateTargetLockWav() {
    const sampleRate = 22050;
    const duration = 0.35;
    final totalSamples = (sampleRate * duration).toInt();
    final pcm = Int16List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final sweepFreq = 1800 + (t / duration) * 1600;
      final s = sin(2 * pi * sweepFreq * t);
      pcm[i] = (s * 26000).clamp(-32768, 32767).toInt();
    }

    return _createWavContainer(pcm, sampleRate: sampleRate);
  }

  Uint8List _generateGlitchWav() {
    const sampleRate = 22050;
    const duration = 0.3;
    final totalSamples = (sampleRate * duration).toInt();
    final pcm = Int16List(totalSamples);
    final rand = Random();

    for (int i = 0; i < totalSamples; i++) {
      final noise = (rand.nextDouble() * 2 - 1) * (i % 25 < 12 ? 1 : -0.7);
      pcm[i] = (noise * 22000).clamp(-32768, 32767).toInt();
    }

    return _createWavContainer(pcm, sampleRate: sampleRate);
  }

  /// Package raw 16-bit PCM samples into standard RIFF WAV header
  Uint8List _createWavContainer(Int16List pcm, {required int sampleRate}) {
    final byteCount = pcm.length * 2;
    final buffer = ByteData(44 + byteCount);

    // RIFF chunk descriptor
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, 36 + byteCount, Endian.little);
    buffer.setUint8(8, 0x57); // 'W'
    buffer.setUint8(9, 0x41); // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // fmt sub-chunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    buffer.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
    buffer.setUint16(22, 1, Endian.little); // NumChannels (1 = mono)
    buffer.setUint32(24, sampleRate, Endian.little); // SampleRate
    buffer.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    buffer.setUint16(32, 2, Endian.little); // BlockAlign
    buffer.setUint16(34, 16, Endian.little); // BitsPerSample

    // data sub-chunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, byteCount, Endian.little);

    // Copy PCM data
    for (int i = 0; i < pcm.length; i++) {
      buffer.setInt16(44 + i * 2, pcm[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:cocord/core/synth.dart';

void _expectValidWav(Uint8List b) {
  expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF');
  expect(String.fromCharCodes(b.sublist(8, 12)), 'WAVE');
  final dataLen = ByteData.sublistView(b).getUint32(40, Endian.little);
  expect(b.length, 44 + dataLen);
  expect(dataLen, greaterThan(0));
}

void main() {
  test('every soundboard sound renders a valid WAV', () {
    for (final s in kSoundboard) {
      _expectValidWav(s.build());
    }
  });

  test('squelch, roger and static render valid WAVs', () {
    _expectValidWav(Synth.squelch(keyup: true));
    _expectValidWav(Synth.squelch(keyup: false));
    _expectValidWav(Synth.rogerBeep());
    _expectValidWav(Synth.staticLoop());
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cocord/core/models.dart';

void main() {
  test('Freq.clamp keeps value in range and rounds to 3 decimals', () {
    expect(Freq.clamp(10), Freq.min);
    expect(Freq.clamp(5000), Freq.max);
    expect(Freq.clamp(144.80000001), 144.8);
  });

  test('Freq.key is topic-safe', () {
    expect(Freq.key(144.8), '144_800');
  });

  test('sanitizeCallsign strips junk, uppercases, caps length', () {
    expect(sanitizeCallsign('  viper-2 !!'), 'VIPER-2');
    expect(sanitizeCallsign('abcdefghijklmnop'), 'ABCDEFGHIJKL');
    expect(sanitizeCallsign('###'), 'BRAVO-06');
  });

  test('randomId is 10 chars and unique-ish', () {
    expect(randomId().length, 10);
    expect(randomId(), isNot(randomId()));
  });
}

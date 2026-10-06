import 'package:cocord/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanitizeName strips control chars, collapses spaces, caps length', () {
    expect(sanitizeName('  Ali \n  Baba\u0000 '), 'Ali Baba');
    expect(sanitizeName('x' * 50).length, Limits.maxName);
    expect(sanitizeName('   '), 'Guest');
  });

  test('randomId is 10 chars and unique-ish', () {
    expect(randomId().length, 10);
    expect(randomId(), isNot(randomId()));
  });

  test('memberColor clamps out-of-range indexes', () {
    expect(memberColor(-5), kMemberColors.first);
    expect(memberColor(999), kMemberColors.last);
  });
}

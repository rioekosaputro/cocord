import 'package:flutter_test/flutter_test.dart';
import 'package:cocord/core/radio/msg_utils.dart';

void main() {
  test('str rejects non-strings and empty text', () {
    expect(MsgUtils.str(null, 10), isNull);
    expect(MsgUtils.str(42, 10), isNull);
    expect(MsgUtils.str('   ', 10), isNull);
  });

  test('str trims, strips control chars and caps length', () {
    expect(MsgUtils.str('  hi\u0000 there ', 20), 'hi there');
    expect(MsgUtils.str('abcdef', 3), 'abc');
  });

  test('flag is true only for boolean true', () {
    expect(MsgUtils.flag(true), isTrue);
    expect(MsgUtils.flag('true'), isFalse);
    expect(MsgUtils.flag(1), isFalse);
  });
}

import 'package:cocord/core/room.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('room key ignores case and extra spaces but not the password', () {
    expect(const RoomInfo('Game  Night').key, const RoomInfo('game night').key);
    expect(const RoomInfo('a', 'x').key, isNot(const RoomInfo('a', 'y').key));
    expect(const RoomInfo('a').key.length, 32);
  });

  test('normalize falls back to the default room', () {
    expect(RoomInfo.normalize('   '), RoomInfo.defaultName);
    expect(RoomInfo.normalize('  Squad   ALPHA '), 'squad alpha');
  });

  test('invite round-trips including password and special characters', () {
    final room = RoomInfo.fromInput('Movie & Chill', 'p@ss word/1');
    final parsed = RoomInfo.parse('hey!\n${room.invite}\nsee you');
    expect(parsed, isNotNull);
    expect(parsed!.name, room.name);
    expect(parsed.password, 'p@ss word/1');
    expect(parsed, room);
  });

  test('parse accepts a plain name and rejects empty or broken links', () {
    expect(RoomInfo.parse('Lobby')!.name, 'lobby');
    expect(RoomInfo.parse('   '), isNull);
    expect(RoomInfo.parse('cocord://join?x=1'), isNull);
  });

  test('json round-trip and equality', () {
    const room = RoomInfo('squad', 'pw');
    expect(RoomInfo.fromJson(room.toJson()), room);
    expect(RoomInfo.fromJson('nope'), isNull);
  });
}

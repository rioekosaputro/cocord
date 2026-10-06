// Manual smoke test (needs internet): two clients meet in a private room and
// exchange a chat broadcast and a direct signal through a real public broker.
// Run: flutter test tool/signaling_smoke_test.dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freqwave_mobile/core/signaling.dart';

void main() {
  test('two clients exchange chat and direct signals', _run,
      timeout: const Timeout(Duration(seconds: 60)));
}

Future<void> _run() async {
  final room = 'smoke_${DateTime.now().millisecondsSinceEpoch}';
  final a = Signaling('smokeaaaaa');
  final b = Signaling('smokebbbbb');
  final gotChat = Completer<String>();
  final gotDirect = Completer<String>();
  b.onBroadcast = (m) {
    if (m['t'] == 'chat' && !gotChat.isCompleted) gotChat.complete('${m['x']}');
  };
  b.onDirect = (m) {
    if (!gotDirect.isCompleted) gotDirect.complete('${m['t']}');
  };
  expect(await a.connect(), isTrue);
  expect(await b.connect(), isTrue);
  a.joinRoom(room);
  b.joinRoom(room);
  await Future<void>.delayed(const Duration(seconds: 1));
  a.sendBroadcast({'t': 'chat', 'x': 'hello ✓ 你好'});
  a.sendDirect('smokebbbbb', {'t': 'offer'});
  expect(await gotChat.future.timeout(const Duration(seconds: 8)),
      'hello ✓ 你好');
  expect(await gotDirect.future.timeout(const Duration(seconds: 8)), 'offer');
  await a.dispose();
  await b.dispose();
}

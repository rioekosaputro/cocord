import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cocord/core/voice/voice_room_manager.dart';
import 'package:cocord/main.dart';

void main() {
  testWidgets('Cocord smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VoiceRoomManager()),
        ],
        child: const CocordApp(),
      ),
    );
    expect(find.byType(CocordApp), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/tactical_theme.dart';
import 'core/voice/voice_room_manager.dart';
import 'presentation/screens/home_rooms_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VoiceRoomManager()),
      ],
      child: const CocordApp(),
    ),
  );
}

class CocordApp extends StatelessWidget {
  const CocordApp({super.key});

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceRoomManager>();

    return MaterialApp(
      title: 'Cocord Voice Comms',
      debugShowCheckedModeBanner: false,
      theme: TacticalTheme.lightTheme,
      darkTheme: TacticalTheme.darkTheme,
      themeMode: voice.themeMode,
      home: const HomeRoomsScreen(),
    );
  }
}

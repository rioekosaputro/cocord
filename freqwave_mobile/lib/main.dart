import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/tactical_theme.dart';
import 'core/audio/radio_audio_manager.dart';
import 'presentation/screens/tactical_radio_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RadioAudioManager()),
      ],
      child: const FreqWaveApp(),
    ),
  );
}

class FreqWaveApp extends StatelessWidget {
  const FreqWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreqWave Tactical Radio',
      debugShowCheckedModeBanner: false,
      theme: TacticalTheme.themeData,
      home: const TacticalRadioScreen(),
    );
  }
}

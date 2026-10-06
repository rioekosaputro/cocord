import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/tactical_theme.dart';
import '../../core/audio/radio_audio_manager.dart';
import '../widgets/rf_oscilloscope.dart';
import '../widgets/ptt_button.dart';
import '../widgets/boombox_card.dart';

class TacticalRadioScreen extends StatelessWidget {
  const TacticalRadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<RadioAudioManager>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TacticalTheme.bgPanel,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: TacticalTheme.accentGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'FREQWAVE',
              style: TextStyle(
                fontFamily: 'ChakraPetch',
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: TacticalTheme.accentAmber),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AND-TAC',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: TacticalTheme.accentAmber,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined, color: TacticalTheme.accentCyan),
            onPressed: () {
              _openChatSheet(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HUD Frequency Big Display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF070B10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TacticalTheme.accentCyan.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      'TUNED FREQUENCY',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        letterSpacing: 2,
                        color: TacticalTheme.accentCyan.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          audio.currentFrequency.toStringAsFixed(3),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'MHz',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            color: TacticalTheme.accentAmber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'CALLSIGN: ${audio.callsign} // CH-07 ALPHA',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: TacticalTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Frequency Dial / Quick Step Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TacticalTheme.accentCyan,
                        side: const BorderSide(color: TacticalTheme.accentCyan),
                      ),
                      onPressed: () => audio.setFrequency(audio.currentFrequency - 0.05),
                      child: const Text('- 0.05 MHz'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TacticalTheme.accentCyan,
                        side: const BorderSide(color: TacticalTheme.accentCyan),
                      ),
                      onPressed: () => audio.setFrequency(audio.currentFrequency + 0.05),
                      child: const Text('+ 0.05 MHz'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Oscilloscope View
              RFOscilloscope(isTransmitting: audio.isTransmitting),
              const SizedBox(height: 16),

              // Large Push-to-Talk (PTT) Button
              PttTacticalButton(
                isTransmitting: audio.isTransmitting,
                onTransmittingStart: () => audio.startTransmitting(),
                onTransmittingEnd: () => audio.stopTransmitting(),
              ),
              const SizedBox(height: 16),

              // Synced Boombox Card
              BoomboxCard(
                isPlaying: audio.isPlayingMusic,
                volume: audio.boomboxVolume,
                onTogglePlay: () => audio.toggleMusic(),
                onVolumeChanged: (v) => audio.setBoomboxVolume(v),
              ),
              const SizedBox(height: 16),

              // Quick Tactical Soundboard Grid
              const Text(
                'TACTICAL SOUNDBOARD',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: TacticalTheme.accentAmber,
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: [
                  _soundPad(context, '📻 Roger That', 'roger'),
                  _soundPad(context, '📯 Airhorn', 'airhorn'),
                  _soundPad(context, '🚨 Siren', 'siren'),
                  _soundPad(context, '📡 Morse', 'morse'),
                  _soundPad(context, '🎯 Locked', 'target'),
                  _soundPad(context, '⚡ Glitch', 'glitch'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _soundPad(BuildContext context, String label, String key) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: TacticalTheme.bgCard,
        foregroundColor: Colors.white,
        side: BorderSide(color: TacticalTheme.accentCyan.withOpacity(0.2)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      onPressed: () {
        context.read<RadioAudioManager>().playSoundboardDrop(key);
      },
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _openChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TacticalTheme.bgPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💬 FREQ CHAT FEED (144.800 MHz)',
                style: TextStyle(
                  fontFamily: 'ChakraPetch',
                  fontWeight: FontWeight.bold,
                  color: TacticalTheme.accentCyan,
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(
                      dense: true,
                      title: Text('VIPER-2: All units check in on 144.8'),
                      subtitle: Text('13:02 // SQUAD SECURE', style: TextStyle(fontSize: 9)),
                    ),
                    ListTile(
                      dense: true,
                      title: Text('GHOST-9: Copy that. Audio squelch crystal clear.'),
                      subtitle: Text('13:04 // SQUAD SECURE', style: TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Transmit message to squad...',
                  filled: true,
                  fillColor: TacticalTheme.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: TacticalTheme.accentCyan),
                  ),
                  suffixIcon: const Icon(Icons.send, color: TacticalTheme.accentCyan),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/tactical_theme.dart';
import '../../core/voice/voice_room_manager.dart';
import '../../data/models/voice_profile.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _callsignController;

  @override
  void initState() {
    super.initState();
    final voice = context.read<VoiceRoomManager>();
    _callsignController = TextEditingController(text: voice.myCallsign);
  }

  @override
  void dispose() {
    _callsignController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceRoomManager>();
    final isDark = voice.isDarkMode;
    final selectedProfile = voice.selectedVoiceProfile;

    return Dialog(
      backgroundColor: isDark ? TacticalTheme.bgPanelDark : TacticalTheme.bgPanelLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650, maxWidth: 440),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TacticalTheme.accentPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: TacticalTheme.accentPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'SETTINGS & VOICE STUDIO',
                  style: TextStyle(
                    fontFamily: 'ChakraPetch',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : TacticalTheme.textPrimaryLight,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : TacticalTheme.textSecondaryLight),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 14),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. APPEARANCE / THEME MODE
                    Text(
                      'APPEARANCE THEME',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDark ? TacticalTheme.accentAmber : TacticalTheme.accentPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _themeOptionCard(
                            title: 'Dark Tactical',
                            icon: Icons.dark_mode_rounded,
                            isSelected: isDark,
                            isDark: isDark,
                            onTap: () => voice.setThemeMode(ThemeMode.dark),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _themeOptionCard(
                            title: 'Soft Light',
                            icon: Icons.light_mode_rounded,
                            isSelected: !isDark,
                            isDark: isDark,
                            onTap: () => voice.setThemeMode(ThemeMode.light),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. NATURAL VOICE CHANGER STUDIO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NATURAL VOICE CHANGER',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDark ? TacticalTheme.accentGreen : TacticalTheme.accentSuccess,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: TacticalTheme.accentGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AI ACOUSTIC PITCH',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: TacticalTheme.accentGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Natural acoustic voice transformer without robotic artifacts.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? TacticalTheme.textSecondaryDark : TacticalTheme.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Voice Profiles List
                    Column(
                      children: VoiceProfile.presets.map((profile) {
                        final isSelected = profile.id == selectedProfile.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => voice.setVoiceProfile(profile),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? TacticalTheme.accentPrimary.withOpacity(0.12)
                                    : (isDark ? TacticalTheme.bgCardDark : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? TacticalTheme.accentPrimary
                                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? TacticalTheme.accentPrimary
                                          : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      profile.icon,
                                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : TacticalTheme.textPrimaryLight),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              profile.name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : TacticalTheme.textPrimaryLight,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: TacticalTheme.accentPrimary.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                profile.tag,
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 7,
                                                  fontWeight: FontWeight.bold,
                                                  color: TacticalTheme.accentPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          profile.description,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? TacticalTheme.textSecondaryDark : TacticalTheme.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded,
                                        color: TacticalTheme.accentPrimary, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Live Mic Test Loopback Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? TacticalTheme.bgCardDark : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: voice.isMicTestActive
                              ? TacticalTheme.accentGreen
                              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            voice.isMicTestActive ? Icons.hearing_rounded : Icons.hearing_disabled_rounded,
                            color: voice.isMicTestActive ? TacticalTheme.accentGreen : TacticalTheme.accentAmber,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Live Mic Test / Voice Loopback',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  voice.isMicTestActive
                                      ? 'Speaking into mic... Hear your natural voice profile in headphones.'
                                      : 'Test how your transformed voice sounds before joining squad.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? TacticalTheme.textSecondaryDark : TacticalTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: voice.isMicTestActive ? TacticalTheme.accentDanger : TacticalTheme.accentGreen,
                            ),
                            onPressed: () => voice.toggleMicTest(),
                            child: Text(
                              voice.isMicTestActive ? 'STOP TEST' : 'START TEST',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. OPERATOR CALLSIGN
                    Text(
                      'OPERATOR CALLSIGN',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDark ? TacticalTheme.accentCyan : TacticalTheme.accentPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _callsignController,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(
                        color: isDark ? Colors.white : TacticalTheme.textPrimaryLight,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Your Callsign / Name',
                        filled: true,
                        fillColor: isDark ? TacticalTheme.bgCardDark : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save_rounded, color: TacticalTheme.accentPrimary),
                          onPressed: () {
                            if (_callsignController.text.trim().isNotEmpty) {
                              voice.setCallsign(_callsignController.text.trim());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Callsign updated!')),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeOptionCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? TacticalTheme.accentPrimary.withOpacity(0.15)
              : (isDark ? TacticalTheme.bgCardDark : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? TacticalTheme.accentPrimary
                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? TacticalTheme.accentPrimary : (isDark ? Colors.white70 : TacticalTheme.textSecondaryLight), size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? TacticalTheme.accentPrimary : (isDark ? Colors.white : TacticalTheme.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/radio/radio_controller.dart';
import '../theme.dart';
import '../widgets/device_picker.dart';
import '../widgets/network_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _ProfileCard(),
        SizedBox(height: 16),
        DevicePicker(),
        SizedBox(height: 8),
        _AudioSwitches(),
        _MicStatus(),
        SizedBox(height: 16),
        NetworkSettings(),
        SizedBox(height: 16),
        _SessionButtons(),
      ],
    );
  }
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard();

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  late final TextEditingController _ctl = TextEditingController(
      text: context.read<RadioController>().settings.displayName);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _saveName(String v) {
    final r = context.read<RadioController>();
    r.setProfile(name: v);
    _ctl.text = r.settings.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('YOUR PROFILE'),
      TextField(
        controller: _ctl,
        maxLength: Limits.maxName,
        textInputAction: TextInputAction.done,
        onSubmitted: _saveName,
        onTapOutside: (_) => _saveName(_ctl.text),
        decoration: const InputDecoration(
          labelText: 'Display name',
          helperText: 'Shown to everyone in your room.',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 10, children: [
        for (var i = 0; i < kMemberColors.length; i++)
          _ColorDot(
            color: kMemberColors[i],
            selected: r.settings.colorIndex == i,
            onTap: () => r.setProfile(colorIndex: i),
          ),
      ]),
    ]);
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot(
      {required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? Colors.white : Colors.transparent, width: 3),
        ),
        child: selected
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

class _AudioSwitches extends StatelessWidget {
  const _AudioSwitches();

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    final s = r.settings;
    return Column(children: [
      SwitchListTile(
        title: const Text('Volume-down key = push-to-talk'),
        subtitle: const Text('Hold the volume-down button to talk'),
        value: s.volumeKeyPtt,
        onChanged: r.setVolumeKeyPtt,
      ),
      SwitchListTile(
        title: const Text('Roger beep after talking'),
        value: s.rogerBeep,
        onChanged: r.setRogerBeep,
      ),
      SwitchListTile(
        title: const Text('Radio squelch sounds'),
        value: s.squelch,
        onChanged: r.setSquelch,
      ),
      SwitchListTile(
        title: const Text('Ambient static'),
        value: s.staticNoise,
        onChanged: (v) => r.setStatic(v),
      ),
      if (s.staticNoise)
        Slider(
          value: s.staticVolume,
          max: 0.5,
          onChanged: (v) => r.setStatic(true, v),
        ),
      SwitchListTile(
        title: const Text('Sync boombox with the room'),
        subtitle: const Text('Station and play/pause follow everyone in the room'),
        value: s.syncBoombox,
        onChanged: r.setSyncBoombox,
      ),
    ]);
  }
}

class _MicStatus extends StatelessWidget {
  const _MicStatus();

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    return ListTile(
      leading: Icon(r.micGranted ? Icons.mic : Icons.mic_off,
          color: r.micGranted ? AppColors.green : AppColors.red),
      title: Text(r.micGranted ? 'Microphone ready' : 'Microphone not allowed'),
      subtitle: r.micGranted
          ? null
          : const Text('You can listen, but not talk. Tap to open settings.'),
      onTap: r.micGranted ? null : openAppSettings,
    );
  }
}

class _SessionButtons extends StatelessWidget {
  const _SessionButtons();

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('RECONNECT'),
          onPressed: r.joining ? null : r.reconnect,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.power_settings_new),
          label: const Text('GO OFFLINE'),
          onPressed: r.joined ? r.leave : null,
        ),
      ),
    ]);
  }
}

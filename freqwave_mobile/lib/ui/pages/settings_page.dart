import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/radio/radio_controller.dart';
import '../theme.dart';
import '../widgets/network_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _CallsignField(),
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

class _CallsignField extends StatefulWidget {
  const _CallsignField();

  @override
  State<_CallsignField> createState() => _CallsignFieldState();
}

class _CallsignFieldState extends State<_CallsignField> {
  late final TextEditingController _ctl = TextEditingController(
      text: context.read<RadioController>().settings.callsign);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _save(String v) {
    final r = context.read<RadioController>();
    r.setCallsign(v);
    _ctl.text = r.settings.callsign;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctl,
      maxLength: 12,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.done,
      onSubmitted: _save,
      onTapOutside: (_) => _save(_ctl.text),
      decoration: const InputDecoration(
        labelText: 'Callsign',
        helperText: 'Letters, numbers and dashes. Seen by others on air.',
        border: OutlineInputBorder(),
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
        title: const Text('Volume-down key = PTT'),
        subtitle: const Text('Hold the volume-down button to talk'),
        value: s.volumeKeyPtt,
        onChanged: r.setVolumeKeyPtt,
      ),
      SwitchListTile(
        title: const Text('Roger beep'),
        value: s.rogerBeep,
        onChanged: r.setRogerBeep,
      ),
      SwitchListTile(
        title: const Text('Squelch bursts'),
        value: s.squelch,
        onChanged: r.setSquelch,
      ),
      SwitchListTile(
        title: const Text('Ambient radio static'),
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
        title: const Text('Sync boombox with frequency'),
        subtitle: const Text('Station and play/pause follow your friends'),
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

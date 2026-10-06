import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../../core/radio/radio_controller.dart';
import '../theme.dart';

/// Microphone and speaker selectors. Used in Settings and the quick sheet.
class DevicePicker extends StatelessWidget {
  const DevicePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    if (!r.joined || r.inputDevices.isEmpty && r.outputDevices.isEmpty) {
      return const ListTile(
        leading: Icon(Icons.headset_off, color: AppColors.muted),
        title: Text('Audio devices'),
        subtitle: Text('Tune in to choose your speaker and microphone.'),
      );
    }
    return Column(children: [
      _Dropdown(
        icon: Icons.volume_up,
        label: 'Speaker',
        devices: r.outputDevices,
        selected: r.activeOutputId,
        onPick: r.chooseOutput,
      ),
      const SizedBox(height: 12),
      _Dropdown(
        icon: Icons.mic,
        label: 'Microphone',
        devices: r.inputDevices,
        selected: r.activeInputId,
        onPick: r.chooseInput,
      ),
    ]);
  }
}

class _Dropdown extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<MediaDeviceInfo> devices;
  final String? selected;
  final ValueChanged<MediaDeviceInfo> onPick;

  const _Dropdown({
    required this.icon,
    required this.label,
    required this.devices,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      hint: const Text('System default'),
      items: [
        for (final d in devices)
          DropdownMenuItem(
            value: d.deviceId,
            child: Text(d.label.isEmpty ? d.deviceId : d.label,
                overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) {
        if (id == null) return;
        onPick(devices.firstWhere((d) => d.deviceId == id));
      },
    );
  }
}

/// Bottom sheet with the pickers, opened from the radio page.
Future<void> showDeviceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: DevicePicker(),
    ),
  );
}

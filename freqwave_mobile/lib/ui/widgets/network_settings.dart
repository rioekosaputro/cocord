import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/radio/radio_controller.dart';
import '../../core/settings.dart';
import '../theme.dart';

/// Optional own MQTT broker and TURN relay (advanced).
class NetworkSettings extends StatefulWidget {
  const NetworkSettings({super.key});

  @override
  State<NetworkSettings> createState() => _NetworkSettingsState();
}

class _NetworkSettingsState extends State<NetworkSettings> {
  late final _host = _ctl((s) => s.brokerHost);
  late final _port = _ctl((s) => '${s.brokerPort}');
  late final _turn = _ctl((s) => s.turnUrl);
  late final _user = _ctl((s) => s.turnUser);
  late final _pass = _ctl((s) => s.turnPass);

  TextEditingController _ctl(String Function(AppSettings) pick) =>
      TextEditingController(
          text: pick(context.read<RadioController>().settings));

  @override
  void dispose() {
    for (final c in [_host, _port, _turn, _user, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    context.read<RadioController>().setNetwork(
          brokerHost: _host.text,
          brokerPort: int.tryParse(_port.text) ?? 1883,
          turnUrl: _turn.text,
          turnUser: _user.text,
          turnPass: _pass.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Advanced network'),
      subtitle: const Text('Own MQTT broker / TURN relay'),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        const SectionLabel('Leave empty to use the free public brokers.'),
        _field(_host, 'MQTT broker host'),
        _field(_port, 'MQTT port', number: true),
        _field(_turn, 'TURN url (turn:host:3478)'),
        _field(_user, 'TURN username'),
        _field(_pass, 'TURN password', obscure: true),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(onPressed: _save, child: const Text('SAVE')),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool number = false, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}

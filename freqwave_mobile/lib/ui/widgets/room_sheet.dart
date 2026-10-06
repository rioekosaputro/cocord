import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/radio/radio_controller.dart';
import '../../core/room.dart';
import '../theme.dart';

/// Bottom sheet to create/join a room, paste an invite, or reopen a recent.
Future<void> showRoomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: const _RoomSheet(),
    ),
  );
}

class _RoomSheet extends StatefulWidget {
  const _RoomSheet();

  @override
  State<_RoomSheet> createState() => _RoomSheetState();
}

class _RoomSheetState extends State<_RoomSheet> {
  final _name = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _join() {
    final text = _name.text;
    final r = context.read<RadioController>();
    final isInvite = text.contains('cocord://');
    final ok =
        isInvite ? r.joinFromText(text) : r.joinNamed(text, _pass.text);
    if (!ok) {
      r.toast?.call('Type a room name or paste an invite');
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('JOIN OR CREATE A ROOM'),
          TextField(
            controller: _name,
            maxLength: Limits.maxRoomName,
            decoration: const InputDecoration(
              labelText: 'Room name (or paste an invite)',
              border: OutlineInputBorder(),
            ),
          ),
          TextField(
            controller: _pass,
            obscureText: true,
            maxLength: Limits.maxPassword,
            decoration: const InputDecoration(
              labelText: 'Password (optional, makes it private)',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _join, child: const Text('JOIN')),
          ),
          const SizedBox(height: 16),
          const _Recents(),
        ],
      ),
    );
  }
}

class _Recents extends StatelessWidget {
  const _Recents();

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    final items = r.settings.recents;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('RECENT ROOMS'),
        for (final room in items) _RecentTile(room: room),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  final RoomInfo room;
  const _RecentTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final r = context.read<RadioController>();
    final current = room == r.settings.room;
    return ListTile(
      dense: true,
      leading: Icon(room.isPrivate ? Icons.lock : Icons.tag,
          color: current ? AppColors.green : AppColors.muted),
      title: Text(room.name),
      subtitle: current ? const Text('You are here') : null,
      trailing: current
          ? null
          : IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => r.forgetRoom(room)),
      onTap: current
          ? null
          : () {
              r.enterRoom(room);
              Navigator.pop(context);
            },
    );
  }
}

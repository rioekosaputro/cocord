import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/radio/radio_controller.dart';
import '../theme.dart';
import 'room_sheet.dart';

/// Current room card: name, lock state, member count, invite and switch.
class RoomHeader extends StatelessWidget {
  const RoomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RadioController>();
    final room = r.settings.room;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('VOICE ROOM', color: AppColors.blue),
          Row(children: [
            Icon(room.isPrivate ? Icons.lock : Icons.tag,
                size: 22, color: room.isPrivate ? AppColors.amber : AppColors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(room.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            room.isPrivate
                ? 'Private room · only people with the password can join'
                : 'Public room · anyone who types this name can join',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          _Buttons(r),
        ],
      ),
    );
  }
}

class _Buttons extends StatelessWidget {
  final RadioController r;
  const _Buttons(this.r);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: FilledButton.icon(
          icon: const Icon(Icons.swap_horiz),
          label: const Text('SWITCH ROOM'),
          onPressed: () => showRoomSheet(context),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('INVITE'),
          onPressed: r.shareInvite,
        ),
      ),
    ]);
  }
}

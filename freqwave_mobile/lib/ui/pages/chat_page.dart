import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/radio/radio_controller.dart';
import '../theme.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Header(),
        Expanded(child: _MessageList()),
        _Composer(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final room = context.select<RadioController, String>((r) => r.roomName);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        const Icon(Icons.forum_outlined, color: AppColors.blue, size: 18),
        const SizedBox(width: 8),
        Text('#$room',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.blue,
                fontSize: 16)),
      ]),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList();

  @override
  Widget build(BuildContext context) {
    final msgs = context.watch<RadioController>().messages;
    if (msgs.isEmpty) {
      return const Center(
          child: Text('No messages yet.',
              style: TextStyle(color: AppColors.muted)));
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: msgs.length,
      itemBuilder: (_, i) => _Bubble(msgs[msgs.length - 1 - i]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage m;
  const _Bubble(this.m);

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(m.time).format(context);
    if (m.kind == ChatKind.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('$time  ${m.text}',
            style: const TextStyle(
                fontFamily: kMono, fontSize: 11, color: AppColors.dim)),
      );
    }
    final mine = m.kind == ChatKind.local;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: mine ? AppColors.blue.withValues(alpha: 0.25) : AppColors.card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${m.sender}  $time',
                style: TextStyle(
                    fontFamily: kMono,
                    fontSize: 10,
                    color: memberColor(m.colorIndex))),
            const SizedBox(height: 2),
            Text(m.text),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer();

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _send() {
    context.read<RadioController>().sendChat(_ctl.text);
    _ctl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: TextField(
        controller: _ctl,
        maxLength: Limits.maxChat,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _send(),
        decoration: InputDecoration(
          counterText: '',
          hintText: 'Message the room…',
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
              icon: const Icon(Icons.send, color: AppColors.blue),
              onPressed: _send),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/voice/voice_room_manager.dart';
import '../../core/theme/tactical_theme.dart';

class TacticalChatSheet extends StatefulWidget {
  const TacticalChatSheet({super.key});

  @override
  State<TacticalChatSheet> createState() => _TacticalChatSheetState();
}

class _TacticalChatSheetState extends State<TacticalChatSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      context.read<VoiceRoomManager>().sendChatMessage(text);
      _textController.clear();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceRoomManager>();
    final messages = voice.chatMessages;
    final roomName = voice.currentRoom?.name ?? 'VOICE ROOM';

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      height: 480,
      decoration: const BoxDecoration(
        color: TacticalTheme.bgPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '💬 $roomName CHAT',
                style: const TextStyle(
                  fontFamily: 'ChakraPetch',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: TacticalTheme.accentCyan,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: voice.isMeshOnline
                      ? TacticalTheme.accentGreen.withOpacity(0.15)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  voice.isMeshOnline ? '● MESH ONLINE' : '○ P2P STANDBY',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: voice.isMeshOnline
                        ? TacticalTheme.accentGreen
                        : TacticalTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final timeStr =
                    '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: msg.isLocal
                          ? TacticalTheme.accentCyan.withOpacity(0.1)
                          : TacticalTheme.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: msg.isLocal
                            ? TacticalTheme.accentCyan.withOpacity(0.3)
                            : Colors.white10,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              msg.sender,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: msg.isLocal
                                    ? TacticalTheme.accentCyan
                                    : TacticalTheme.accentAmber,
                              ),
                            ),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                color: TacticalTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          msg.text,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Transmit message to room...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: TacticalTheme.bgCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: TacticalTheme.accentCyan),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: TacticalTheme.accentCyan.withOpacity(0.3)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: TacticalTheme.accentCyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.send, size: 20),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

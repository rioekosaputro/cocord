import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/tactical_theme.dart';
import '../../data/models/voice_room.dart';

class RoomInviteSheet extends StatefulWidget {
  final VoiceRoom room;

  const RoomInviteSheet({super.key, required this.room});

  @override
  State<RoomInviteSheet> createState() => _RoomInviteSheetState();
}

class _RoomInviteSheetState extends State<RoomInviteSheet> {
  bool _isCopied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.room.shareableUrl));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _shareNative() {
    Share.share(
      '🎙️ Join my Cocord Voice Room!\nRoom: ${widget.room.name} [${widget.room.id}]\nLink: ${widget.room.shareableUrl}',
      subject: 'Invite to Cocord Voice Room',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: TacticalTheme.bgPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TacticalTheme.accentPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share_rounded, color: TacticalTheme.accentPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INVITE SQUAD TO ROOM',
                      style: TextStyle(
                        fontFamily: 'ChakraPetch',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.room.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TacticalTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Room Code Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TacticalTheme.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ROOM CODE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: TacticalTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.room.id,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: TacticalTheme.accentAmber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Shareable Link Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: TacticalTheme.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TacticalTheme.accentPrimary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: TacticalTheme.accentPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.room.shareableUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(_isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                      color: _isCopied ? TacticalTheme.accentGreen : TacticalTheme.accentPrimary,
                      size: 20),
                  onPressed: _copyToClipboard,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Share Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: TacticalTheme.accentPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text(
              'SHARE INVITE LINK VIA APPS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: _shareNative,
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Anyone clicking the link will automatically open Cocord and join this Voice Room.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: TacticalTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

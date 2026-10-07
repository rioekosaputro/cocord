import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/tactical_theme.dart';
import '../../core/voice/voice_room_manager.dart';

class CreateRoomDialog extends StatefulWidget {
  const CreateRoomDialog({super.key});

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Room Name')),
      );
      return;
    }

    context.read<VoiceRoomManager>().createRoom(
          name: name,
          customCode: code.isNotEmpty ? code : null,
          description: desc,
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TacticalTheme.bgPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  child: const Icon(Icons.add_to_photos_rounded,
                      color: TacticalTheme.accentPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'CREATE VOICE ROOM',
                  style: TextStyle(
                    fontFamily: 'ChakraPetch',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Room Name',
                labelStyle: const TextStyle(color: TacticalTheme.textSecondary),
                hintText: 'e.g. Tactical Squad Alpha',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: TacticalTheme.bgCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
              decoration: InputDecoration(
                labelText: 'Custom Code / ID (Optional)',
                labelStyle: const TextStyle(color: TacticalTheme.textSecondary),
                hintText: 'e.g. SQUAD-99',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: TacticalTheme.bgCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Topic / Description (Optional)',
                labelStyle: const TextStyle(color: TacticalTheme.textSecondary),
                hintText: 'e.g. Low latency voice operations',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: TacticalTheme.bgCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CANCEL', style: TextStyle(color: TacticalTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TacticalTheme.accentPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submit,
                    child: const Text('CREATE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

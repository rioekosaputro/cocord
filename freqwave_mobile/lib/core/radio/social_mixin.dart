import 'package:flutter/services.dart';

import '../models.dart';
import '../synth.dart';
import 'boombox_mixin.dart';
import 'msg_utils.dart';
import 'radio_base.dart';

/// Chat, soundboard drops and room invites.
mixin SocialMixin on RadioBase, BoomboxMixin {
  void sendChat(String raw) {
    final text = MsgUtils.str(raw, Limits.maxChat);
    if (text == null) return;
    if (!joined) {
      toast?.call('Tune in to send messages');
      return;
    }
    addMessage(ChatKind.local, settings.displayName, text, settings.colorIndex);
    signaling?.sendBroadcast({
      't': 'chat',
      'cs': settings.displayName,
      'cl': settings.colorIndex,
      'x': text,
    });
  }

  void openChat() {
    chatVisible = true;
    unread = 0;
    notifyListeners();
  }

  void closeChat() => chatVisible = false;

  void dropSound(String key) {
    final def = kSoundboard.where((s) => s.key == key);
    if (def.isEmpty) return;
    HapticFeedback.selectionClick();
    sfx.soundboard(key);
    if (!joined) return;
    signaling?.sendBroadcast(
        {'t': 'snd', 'cs': settings.displayName, 'n': key});
    addSystem('You dropped sound: ${def.first.label.toUpperCase()}');
  }

  /// Copies a tappable invite for the current room to the clipboard.
  Future<void> shareInvite() async {
    await Clipboard.setData(ClipboardData(text: settings.room.invite));
    toast?.call('Invite copied. Paste it to your friends!');
  }
}

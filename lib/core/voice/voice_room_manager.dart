import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/voice_room.dart';
import '../../data/models/room_participant.dart';
import '../../data/models/voice_profile.dart';
import '../services/sound_synth_service.dart';
import '../services/webrtc_voice_service.dart';
import '../services/deep_link_service.dart';

class ChatMessageItem {
  final String sender;
  final String text;
  final DateTime timestamp;
  final bool isLocal;

  ChatMessageItem({
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isLocal,
  });
}

class VoiceRoomManager extends ChangeNotifier {
  final SoundSynthService _synthService = SoundSynthService();
  final WebRtcVoiceService _webrtcService = WebRtcVoiceService();
  final DeepLinkService _deepLinkService = DeepLinkService();

  String _myCallsign = 'BRAVO-06';
  ThemeMode _themeMode = ThemeMode.dark;
  VoiceProfile _selectedVoiceProfile = VoiceProfile.presets.first;
  bool _isMicTestActive = false;

  VoiceRoom? _currentRoom;
  bool _isTransmitting = false;
  bool _isMuted = false;
  bool _isDeafened = false;
  bool _isPttMode = true; // True: Push-to-Talk, False: Open Mic
  bool _isMeshOnline = false;

  final List<RoomParticipant> _participants = [];
  final List<ChatMessageItem> _chatMessages = [];

  // Public / Featured Channels
  final List<VoiceRoom> _publicChannels = [
    VoiceRoom(
      id: 'ALPHA-01',
      name: 'Squad Tactical Alpha',
      description: 'Primary low-latency encrypted squad room.',
      hostCallsign: 'COMMANDER',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    VoiceRoom(
      id: 'BRAVO-02',
      name: 'Operations & Recon',
      description: 'High-frequency mission coordination channel.',
      hostCallsign: 'GHOST-9',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    VoiceRoom(
      id: 'SECURE-99',
      name: 'Direct Secure Line',
      description: 'Point-to-point WebRTC voice mesh.',
      hostCallsign: 'OVERLORD',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  // Getters
  String get myCallsign => _myCallsign;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  VoiceProfile get selectedVoiceProfile => _selectedVoiceProfile;
  bool get isMicTestActive => _isMicTestActive;

  VoiceRoom? get currentRoom => _currentRoom;
  bool get isInRoom => _currentRoom != null;
  bool get isTransmitting => _isTransmitting;
  bool get isMuted => _isMuted;
  bool get isDeafened => _isDeafened;
  bool get isPttMode => _isPttMode;
  bool get isMeshOnline => _isMeshOnline;
  List<RoomParticipant> get participants => List.unmodifiable(_participants);
  List<VoiceRoom> get publicChannels => List.unmodifiable(_publicChannels);
  List<ChatMessageItem> get chatMessages => List.unmodifiable(_chatMessages);

  VoiceRoomManager() {
    _initManager();
  }

  Future<void> _initManager() async {
    // 1. Inisialisasi WebRTC Hardware Voice Service
    await _webrtcService.init(
      frequency: 144.800,
      callsign: _myCallsign,
    );

    // 2. Inisialisasi Deep Linking Listener
    _deepLinkService.onRoomInviteReceived = (roomId) {
      debugPrint('[VoiceRoomManager] Auto-joining room from link: $roomId');
      joinRoom(roomId);
    };
    await _deepLinkService.init();

    // 3. Listener WebRTC saat ada anggota yang berbicara
    _webrtcService.onPeerTransmitting = (peerCallsign, transmitting) {
      _updateParticipantSpeaking(peerCallsign, transmitting);
      if (transmitting) {
        _synthService.playSquelchBurst(isKeyup: true);
      } else {
        _synthService.playRogerBeep();
      }
      notifyListeners();
    };

    // 4. Listener Chat Room
    _webrtcService.onChatMessageReceived = (text, sender) {
      _chatMessages.add(ChatMessageItem(
        sender: sender,
        text: text,
        timestamp: DateTime.now(),
        isLocal: false,
      ));
      notifyListeners();
    };

    // 5. Listener status jaringan mesh
    _webrtcService.onSignalingStatusChanged = (connected) {
      _isMeshOnline = connected;
      notifyListeners();
    };
  }

  // ---------------------------------------------------------------------------
  // THEME & SETTINGS
  // ---------------------------------------------------------------------------

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setVoiceProfile(VoiceProfile profile) {
    _selectedVoiceProfile = profile;
    _synthService.playRogerBeep();
    notifyListeners();
  }

  void toggleMicTest() {
    _isMicTestActive = !_isMicTestActive;
    if (_isMicTestActive) {
      _synthService.playSquelchBurst(isKeyup: true);
    } else {
      _synthService.playRogerBeep();
    }
    notifyListeners();
  }

  void setCallsign(String newCallsign) {
    if (newCallsign.trim().isEmpty) return;
    _myCallsign = newCallsign.trim().toUpperCase();
    _webrtcService.setCallsign(_myCallsign);
    if (isInRoom) {
      _updateSelfParticipant();
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ROOM MANAGEMENT (CREATE, JOIN, LEAVE, INVITE)
  // ---------------------------------------------------------------------------

  void createRoom({
    required String name,
    String? customCode,
    String description = '',
  }) {
    final roomId = (customCode != null && customCode.trim().isNotEmpty)
        ? customCode.trim().toUpperCase()
        : 'ROOM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final newRoom = VoiceRoom(
      id: roomId,
      name: name.trim().isEmpty ? 'Voice Room #$roomId' : name.trim(),
      description: description.trim(),
      hostCallsign: _myCallsign,
      createdAt: DateTime.now(),
    );

    _enterRoom(newRoom, isHost: true);
  }

  void joinRoom(String roomId, {String? roomName}) {
    final cleanId = roomId.trim().toUpperCase();
    if (cleanId.isEmpty) return;

    // Cari dari public channel jika ada
    final existing = _publicChannels.firstWhere(
      (r) => r.id == cleanId,
      orElse: () => VoiceRoom(
        id: cleanId,
        name: roomName ?? 'Voice Room #$cleanId',
        description: 'WebRTC P2P Voice Channel',
        hostCallsign: 'HOST',
        createdAt: DateTime.now(),
      ),
    );

    _enterRoom(existing, isHost: existing.hostCallsign == _myCallsign);
  }

  void _enterRoom(VoiceRoom room, {required bool isHost}) {
    _currentRoom = room;
    _participants.clear();
    _chatMessages.clear();

    // Tambahkan diri sendiri sebagai partisipan
    _participants.add(RoomParticipant(
      id: 'self',
      callsign: _myCallsign,
      isHost: isHost,
      joinedAt: DateTime.now(),
      avatarColorIndex: _myCallsign.hashCode.abs() % 5,
    ));

    // Tambahkan demo squad peer yang sudah standby di room
    _participants.add(RoomParticipant(
      id: 'peer_1',
      callsign: 'VIPER-2',
      isHost: !isHost,
      joinedAt: DateTime.now().subtract(const Duration(minutes: 3)),
      avatarColorIndex: 2,
    ));

    _chatMessages.add(ChatMessageItem(
      sender: 'SYSTEM',
      text: 'Connected to Voice Room ${room.id} (${room.name}). WebRTC encrypted mesh ready.',
      timestamp: DateTime.now(),
      isLocal: false,
    ));

    // Connect WebRTC signaling channel for this Room ID
    _webrtcService.setFrequency(room.id.hashCode.abs() % 1000 + 100.0);
    _synthService.playRogerBeep();

    notifyListeners();
  }

  void leaveRoom() {
    if (!isInRoom) return;
    _synthService.playSquelchBurst(isKeyup: false);
    _currentRoom = null;
    _participants.clear();
    _chatMessages.clear();
    _isTransmitting = false;
    _webrtcService.stopTransmitting();
    notifyListeners();
  }

  Future<void> shareRoomInvite() async {
    if (_currentRoom == null) return;
    final inviteLink = _currentRoom!.shareableUrl;
    final shareText =
        '🎙️ Join my Cocord Voice Room!\nRoom: ${_currentRoom!.name} [${_currentRoom!.id}]\nLink: $inviteLink';

    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: inviteLink));

    // Open native Android Share Dialog
    await Share.share(
      shareText,
      subject: 'Invite to Cocord Voice Room: ${_currentRoom!.name}',
    );
  }

  // ---------------------------------------------------------------------------
  // VOICE CONTROL & PTT TRANSMISSION
  // ---------------------------------------------------------------------------

  void startTransmitting() {
    if (_isMuted || _isTransmitting) return;
    _isTransmitting = true;

    _webrtcService.startTransmitting();
    _synthService.playSquelchBurst(isKeyup: true);
    _updateSelfSpeaking(true);
    notifyListeners();
  }

  void stopTransmitting() {
    if (!_isTransmitting) return;
    _isTransmitting = false;

    _webrtcService.stopTransmitting();
    _synthService.playRogerBeep();
    _updateSelfSpeaking(false);
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted && _isTransmitting) {
      stopTransmitting();
    }
    _updateSelfMuteStatus();
    notifyListeners();
  }

  void toggleDeafen() {
    _isDeafened = !_isDeafened;
    if (_isDeafened && !_isMuted) {
      _isMuted = true;
      if (_isTransmitting) stopTransmitting();
    }
    notifyListeners();
  }

  void togglePttMode() {
    _isPttMode = !_isPttMode;
    if (!_isPttMode) {
      // Switched to Open Mic / VAD mode
      startTransmitting();
    } else {
      // Switched to PTT mode
      stopTransmitting();
    }
    notifyListeners();
  }

  void sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    _chatMessages.add(ChatMessageItem(
      sender: _myCallsign,
      text: text.trim(),
      timestamp: DateTime.now(),
      isLocal: true,
    ));
    _webrtcService.sendChatMessage(text.trim());
    notifyListeners();
  }

  // Helper updates
  void _updateSelfSpeaking(bool speaking) {
    final idx = _participants.indexWhere((p) => p.id == 'self');
    if (idx != -1) {
      _participants[idx] = _participants[idx].copyWith(isSpeaking: speaking);
    }
  }

  void _updateSelfMuteStatus() {
    final idx = _participants.indexWhere((p) => p.id == 'self');
    if (idx != -1) {
      _participants[idx] = _participants[idx].copyWith(isMuted: _isMuted);
    }
  }

  void _updateSelfParticipant() {
    final idx = _participants.indexWhere((p) => p.id == 'self');
    if (idx != -1) {
      _participants[idx] = _participants[idx].copyWith(callsign: _myCallsign);
    }
  }

  void _updateParticipantSpeaking(String callsign, bool speaking) {
    final idx = _participants.indexWhere((p) => p.callsign == callsign);
    if (idx != -1) {
      _participants[idx] = _participants[idx].copyWith(isSpeaking: speaking);
    } else if (speaking) {
      // Jika peer belum ada di list, otomatis tambahkan
      _participants.add(RoomParticipant(
        id: 'peer_${callsign.hashCode}',
        callsign: callsign,
        isSpeaking: true,
        joinedAt: DateTime.now(),
        avatarColorIndex: callsign.hashCode.abs() % 5,
      ));
    }
  }

  @override
  void dispose() {
    _synthService.dispose();
    _webrtcService.dispose();
    _deepLinkService.dispose();
    super.dispose();
  }
}

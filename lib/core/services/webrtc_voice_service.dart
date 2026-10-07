import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:audio_session/audio_session.dart';

/// Real-Time WebRTC P2P Voice & Mesh Walkie-Talkie Service
/// Handles hardware microphone capture (Wired headset & Bluetooth TWS SCO),
/// PTT audio track toggling, STUN peer connections, and signaling.
class WebRtcVoiceService {
  MediaStream? _localStream;
  MediaStreamTrack? _localAudioTrack;
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};

  double _currentFrequency = 144.800;
  String _callsign = 'BRAVO-06';
  String _clientId = '';
  WebSocket? _signalingSocket;
  Timer? _reconnectTimer;
  bool _isInitialized = false;
  bool _isTransmitting = false;

  // Event Callbacks
  Function(String callsign, bool isTransmitting)? onPeerTransmitting;
  Function(String callsign, MediaStream stream)? onRemoteStreamReceived;
  Function(List<String> peers)? onPeerListUpdated;
  Function(String text, String senderCallsign)? onChatMessageReceived;
  Function(String soundKey, String senderCallsign)? onSoundboardReceived;
  Function(bool isConnected)? onSignalingStatusChanged;

  final Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun.ekiga.net'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  bool get isTransmitting => _isTransmitting;
  bool get hasLocalMic => _localAudioTrack != null;

  /// Inisialisasi Hardware Audio & Capture Microphone
  Future<void> init({required double frequency, required String callsign}) async {
    if (_isInitialized) return;
    _currentFrequency = frequency;
    _callsign = callsign;
    _clientId = 'and_${DateTime.now().millisecondsSinceEpoch % 100000}';

    await _configureHardwareAudioSession();
    await _initLocalMicrophone();
    _connectSignaling();
    _isInitialized = true;
  }

  /// Konfigurasi AudioSession untuk Telephony / Speech, Headset Kabel & Bluetooth TWS SCO
  Future<void> _configureHardwareAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      await session.setActive(true);
      debugPrint('[WebRTC-Voice] Hardware AudioSession configured for Voice & Bluetooth SCO');
    } catch (e) {
      debugPrint('[WebRTC-Voice] AudioSession config error: $e');
    }
  }

  /// Capture Local Mic via flutter_webrtc
  Future<void> _initLocalMicrophone() async {
    try {
      final mediaConstraints = <String, dynamic>{
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': false, // Karakter analog taktis
          'autoGainControl': true,
          'highpassFilter': true,
        },
        'video': false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      final tracks = _localStream?.getAudioTracks();
      if (tracks != null && tracks.isNotEmpty) {
        _localAudioTrack = tracks.first;
        // Default mute sampai tombol PTT ditekan
        _localAudioTrack?.enabled = false;
        debugPrint('[WebRTC-Voice] Local Microphone captured successfully');
      }
    } catch (e) {
      debugPrint('[WebRTC-Voice] Error capturing local microphone: $e');
    }
  }

  /// PTT Start - Buka mic stream & kirim sinyal TX ke squad
  void startTransmitting() {
    if (_isTransmitting) return;
    _isTransmitting = true;

    // Unmute track lokal
    _localAudioTrack?.enabled = true;

    // Broadcast status TX Start ke semua peer di frekuensi yang sama
    _broadcastSignalingMessage({
      'type': 'tx_start',
      'callsign': _callsign,
      'frequency': _currentFrequency.toStringAsFixed(3),
      'from': _clientId,
    });

    debugPrint('[WebRTC-Voice] PTT ACTIVE: Audio streaming enabled');
  }

  /// PTT Stop - Mute mic stream & kirim sinyal TX stop
  void stopTransmitting() {
    if (!_isTransmitting) return;
    _isTransmitting = false;

    // Mute track lokal kembali
    _localAudioTrack?.enabled = false;

    // Broadcast status TX Stop ke semua peer
    _broadcastSignalingMessage({
      'type': 'tx_stop',
      'callsign': _callsign,
      'frequency': _currentFrequency.toStringAsFixed(3),
      'from': _clientId,
    });

    debugPrint('[WebRTC-Voice] PTT RELEASED: Audio streaming muted');
  }

  /// Ganti Frekuensi Kanal
  void setFrequency(double freq) {
    _currentFrequency = freq;
    _closeAllPeerConnections();
    _broadcastSignalingMessage({
      'type': 'join_frequency',
      'callsign': _callsign,
      'frequency': _currentFrequency.toStringAsFixed(3),
      'from': _clientId,
    });
  }

  /// Update Callsign
  void setCallsign(String callsign) {
    _callsign = callsign;
  }

  /// Kirim Pesan Obrolan Teks ke Frekuensi
  void sendChatMessage(String text) {
    _broadcastSignalingMessage({
      'type': 'chat_message',
      'callsign': _callsign,
      'frequency': _currentFrequency.toStringAsFixed(3),
      'text': text,
      'from': _clientId,
    });
  }

  /// Trigger Soundboard Drop ke Squad
  void sendSoundboardDrop(String soundKey) {
    _broadcastSignalingMessage({
      'type': 'soundboard_drop',
      'callsign': _callsign,
      'frequency': _currentFrequency.toStringAsFixed(3),
      'sound': soundKey,
      'from': _clientId,
    });
  }

  // ---------------------------------------------------------------------------
  // SIGNALING & P2P MESH MANAGEMENT
  // ---------------------------------------------------------------------------

  void _connectSignaling() {
    try {
      // Free public signaling / fallback broker for WebRTC radio rooms
      const signalingUrl = 'wss://signaling.freqwave.app/ws';
      WebSocket.connect(signalingUrl)
          .timeout(const Duration(seconds: 4))
          .then((ws) {
        _signalingSocket = ws;
        onSignalingStatusChanged?.call(true);
        debugPrint('[WebRTC-Signaling] Connected to Signaling Gateway');

        _signalingSocket!.listen(
          (data) => _handleSignalingMessage(data.toString()),
          onDone: () {
            onSignalingStatusChanged?.call(false);
            _scheduleReconnect();
          },
          onError: (err) {
            onSignalingStatusChanged?.call(false);
            _scheduleReconnect();
          },
        );

        // Join room kanal saat ini
        _broadcastSignalingMessage({
          'type': 'join_frequency',
          'callsign': _callsign,
          'frequency': _currentFrequency.toStringAsFixed(3),
          'from': _clientId,
        });
      }).catchError((_) {
        // Fallback local simulated mesh jika signaling server eksternal offline
        onSignalingStatusChanged?.call(false);
        _scheduleReconnect();
      });
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 15), () {
      if (_signalingSocket == null || _signalingSocket?.readyState != WebSocket.open) {
        _connectSignaling();
      }
    });
  }

  void _broadcastSignalingMessage(Map<String, dynamic> data) {
    if (_signalingSocket != null && _signalingSocket!.readyState == WebSocket.open) {
      _signalingSocket!.add(jsonEncode(data));
    }
    // Juga kirim lewat P2P DataChannels aktif
    final jsonStr = jsonEncode(data);
    for (final dc in _dataChannels.values) {
      if (dc.state == RTCDataChannelState.RTCDataChannelOpen) {
        dc.send(RTCDataChannelMessage(jsonStr));
      }
    }
  }

  void _handleSignalingMessage(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final from = data['from'] as String?;
      final senderCallsign = data['callsign'] as String? ?? 'SQUAD-UNIT';

      if (from == _clientId) return; // Abaikan pesan dari diri sendiri

      switch (type) {
        case 'tx_start':
          onPeerTransmitting?.call(senderCallsign, true);
          break;
        case 'tx_stop':
          onPeerTransmitting?.call(senderCallsign, false);
          break;
        case 'chat_message':
          final text = data['text'] as String? ?? '';
          onChatMessageReceived?.call(text, senderCallsign);
          break;
        case 'soundboard_drop':
          final sound = data['sound'] as String? ?? '';
          onSoundboardReceived?.call(sound, senderCallsign);
          break;
        case 'join_frequency':
          _createOfferForPeer(from!, senderCallsign);
          break;
        case 'offer':
          _handleOffer(from!, data['sdp'] as String);
          break;
        case 'answer':
          _handleAnswer(from!, data['sdp'] as String);
          break;
        case 'candidate':
          _handleCandidate(from!, data['candidate'] as Map<String, dynamic>);
          break;
      }
    } catch (e) {
      debugPrint('[WebRTC-Signaling] Message parse error: $e');
    }
  }

  Future<void> _createOfferForPeer(String peerId, String peerCallsign) async {
    try {
      final pc = await _createPeerConnection(peerId, peerCallsign);
      final offer = await pc.createOffer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': 0});
      await pc.setLocalDescription(offer);

      _broadcastSignalingMessage({
        'type': 'offer',
        'sdp': offer.sdp,
        'to': peerId,
        'from': _clientId,
        'callsign': _callsign,
      });
    } catch (e) {
      debugPrint('[WebRTC] Error creating offer: $e');
    }
  }

  Future<void> _handleOffer(String peerId, String sdp) async {
    try {
      final pc = await _createPeerConnection(peerId, 'SQUAD');
      await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      _broadcastSignalingMessage({
        'type': 'answer',
        'sdp': answer.sdp,
        'to': peerId,
        'from': _clientId,
        'callsign': _callsign,
      });
    } catch (e) {
      debugPrint('[WebRTC] Error handling offer: $e');
    }
  }

  Future<void> _handleAnswer(String peerId, String sdp) async {
    try {
      final pc = _peerConnections[peerId];
      if (pc != null) {
        await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
      }
    } catch (e) {
      debugPrint('[WebRTC] Error handling answer: $e');
    }
  }

  Future<void> _handleCandidate(String peerId, Map<String, dynamic> candMap) async {
    try {
      final pc = _peerConnections[peerId];
      if (pc != null) {
        final candidate = RTCIceCandidate(
          candMap['candidate'],
          candMap['sdpMid'],
          candMap['sdpMLineIndex'],
        );
        await pc.addCandidate(candidate);
      }
    } catch (e) {
      debugPrint('[WebRTC] Error adding candidate: $e');
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(String peerId, String peerCallsign) async {
    final pc = await createPeerConnection(_iceConfig);
    _peerConnections[peerId] = pc;

    // Tambahkan audio track mikrofon lokal
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });
    }

    // Tangkap stream suara dari peer remote
    pc.onTrack = (event) {
      if (event.track.kind == 'audio' && event.streams.isNotEmpty) {
        final remoteStream = event.streams.first;
        onRemoteStreamReceived?.call(peerCallsign, remoteStream);
        debugPrint('[WebRTC] Received remote voice audio from $peerCallsign');
      }
    };

    // ICE Candidate Exchange
    pc.onIceCandidate = (candidate) {
      _broadcastSignalingMessage({
        'type': 'candidate',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
        'to': peerId,
        'from': _clientId,
      });
    };

    return pc;
  }

  void _closeAllPeerConnections() {
    for (final pc in _peerConnections.values) {
      pc.close();
    }
    _peerConnections.clear();
    _dataChannels.clear();
  }

  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    _signalingSocket?.close();
    _closeAllPeerConnections();
    _localAudioTrack?.stop();
    _localStream?.dispose();
    _isInitialized = false;
  }
}

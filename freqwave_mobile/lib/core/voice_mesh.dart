import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'signaling.dart';

class _Link {
  final String peerId;
  final bool offerer;
  RTCPeerConnection? pc;
  bool remoteSet = false;
  final List<RTCIceCandidate> pendingIce = [];
  _Link(this.peerId, this.offerer);
}

/// Full-mesh WebRTC audio between everyone in a room.
/// The local mic track stays disabled (silent) until [setTransmit] is true.
/// Without a mic the mesh runs in listen-only mode.
class VoiceMesh {
  final String myId;
  final void Function(String peerId, Json signal) sendSignal;
  final void Function(String peerId, String state) onLinkState;
  final List<Map<String, dynamic>> iceServers;

  MediaStream? _local;
  MediaStreamTrack? _mic;
  final Map<String, _Link> _links = {};
  final List<MediaStreamTrack> _remoteTracks = [];
  bool _remoteMuted = false;
  bool _disposed = false;

  VoiceMesh({
    required this.myId,
    required this.sendSignal,
    required this.onLinkState,
    required this.iceServers,
  });

  bool get hasMic => _mic != null;

  /// Opens the microphone (permission must already be granted).
  Future<bool> start() async {
    try {
      _local = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
      final tracks = _local!.getAudioTracks();
      if (tracks.isEmpty) return false;
      _mic = tracks.first..enabled = false;
      await Helper.setSpeakerphoneOn(true);
      return true;
    } catch (e) {
      debugPrint('[VoiceMesh] getUserMedia failed: $e');
      return false;
    }
  }

  void setTransmit(bool on) => _mic?.enabled = on;

  void setRemoteMuted(bool muted) {
    _remoteMuted = muted;
    for (final t in _remoteTracks) {
      t.enabled = !muted;
    }
  }

  bool isLinked(String peerId) => _links.containsKey(peerId);

  /// The lower id sends the offer, which avoids offer collisions.
  bool isOfferer(String peerId) => myId.compareTo(peerId) < 0;

  Future<void> connect(String peerId) async {
    if (_disposed || _links.containsKey(peerId)) return;
    final link = await _create(peerId, isOfferer(peerId));
    if (link == null || !link.offerer) return;
    try {
      final offer = await link.pc!.createOffer({'offerToReceiveAudio': 1});
      await link.pc!.setLocalDescription(offer);
      sendSignal(peerId, {'t': 'offer', 'sdp': offer.sdp});
    } catch (e) {
      debugPrint('[VoiceMesh] offer to $peerId failed: $e');
      _fail(peerId);
    }
  }

  void _fail(String peerId) {
    drop(peerId);
    onLinkState(peerId, 'failed');
  }

  Future<_Link?> _create(String peerId, bool offerer) async {
    final link = _Link(peerId, offerer);
    _links[peerId] = link;
    try {
      final pc = await createPeerConnection(
          {'iceServers': iceServers, 'sdpSemantics': 'unified-plan'});
      link.pc = pc;
      _wire(link, pc);
      await _attachAudio(pc);
      return link;
    } catch (e) {
      debugPrint('[VoiceMesh] create link $peerId failed: $e');
      _fail(peerId);
      return null;
    }
  }

  Future<void> _attachAudio(RTCPeerConnection pc) async {
    final mic = _mic;
    if (mic != null) {
      await pc.addTrack(mic, _local!);
      return;
    }
    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
  }

  void _wire(_Link link, RTCPeerConnection pc) {
    final peerId = link.peerId;
    pc.onIceCandidate = (c) {
      if (c.candidate == null) return;
      sendSignal(peerId, {
        't': 'ice',
        'c': c.candidate,
        'm': c.sdpMid,
        'i': c.sdpMLineIndex,
      });
    };
    pc.onTrack = (RTCTrackEvent e) {
      if (e.track.kind != 'audio') return;
      e.track.enabled = !_remoteMuted;
      _remoteTracks.add(e.track);
    };
    pc.onConnectionState = (s) => _onState(link, s);
  }

  void _onState(_Link link, RTCPeerConnectionState s) {
    final id = link.peerId;
    if (_disposed || _links[id] != link) return;
    if (s == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      onLinkState(id, 'connected');
    } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
      onLinkState(id, 'connecting');
    } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
        s == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      _fail(id);
    }
  }

  /// Handle an offer/answer/ice message from [from].
  Future<void> onSignal(String from, Json msg) async {
    if (_disposed) return;
    try {
      switch (msg['t']) {
        case 'offer':
          await _onOffer(from, msg['sdp']);
        case 'answer':
          await _onAnswer(from, msg['sdp']);
        case 'ice':
          await _onIce(from, msg);
      }
    } catch (e) {
      debugPrint('[VoiceMesh] signal from $from failed: $e');
    }
  }

  Future<void> _onOffer(String from, Object? sdp) async {
    if (sdp is! String) return;
    if (_links.containsKey(from)) drop(from); // a fresh offer replaces it
    final link = await _create(from, false);
    if (link == null) return;
    final pc = link.pc!;
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    link.remoteSet = true;
    await _flushIce(link);
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    sendSignal(from, {'t': 'answer', 'sdp': answer.sdp});
  }

  Future<void> _onAnswer(String from, Object? sdp) async {
    final link = _links[from];
    if (link == null || !link.offerer || sdp is! String) return;
    await link.pc!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
    link.remoteSet = true;
    await _flushIce(link);
  }

  Future<void> _onIce(String from, Json msg) async {
    final link = _links[from];
    final c = msg['c'];
    if (link == null || c is! String) return;
    final m = msg['m'];
    final i = msg['i'];
    final cand = RTCIceCandidate(c, m is String ? m : null, i is int ? i : null);
    if (link.remoteSet) {
      await link.pc?.addCandidate(cand);
    } else {
      link.pendingIce.add(cand);
    }
  }

  Future<void> _flushIce(_Link link) async {
    for (final c in link.pendingIce) {
      await link.pc?.addCandidate(c);
    }
    link.pendingIce.clear();
  }

  void drop(String peerId) {
    final pc = _links.remove(peerId)?.pc;
    if (pc == null) return;
    pc.onConnectionState = null;
    pc.onIceCandidate = null;
    pc.onTrack = null;
    pc.close();
    pc.dispose();
  }

  void dropAll() {
    for (final id in _links.keys.toList()) {
      drop(id);
    }
    _remoteTracks.clear();
  }

  Future<void> dispose() async {
    _disposed = true;
    dropAll();
    _mic?.enabled = false;
    await _local?.dispose();
    _local = null;
    _mic = null;
  }
}

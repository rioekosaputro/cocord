import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  Function(String roomId)? onRoomInviteReceived;

  Future<void> init() async {
    try {
      // 1. Check if app was opened with a cold start deep link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }

      // 2. Listen for incoming deep links while app is in foreground/background
      _linkSub = _appLinks.uriLinkStream.listen(
        (uri) => _handleIncomingUri(uri),
        onError: (err) => debugPrint('[DeepLink] Stream error: $err'),
      );
    } catch (e) {
      debugPrint('[DeepLink] Init error: $e');
    }
  }

  void _handleIncomingUri(Uri uri) {
    debugPrint('[DeepLink] Received incoming link: $uri');
    final roomId = extractRoomIdFromUri(uri);
    if (roomId != null && roomId.isNotEmpty) {
      debugPrint('[DeepLink] Auto-joining Voice Room ID: $roomId');
      onRoomInviteReceived?.call(roomId);
    }
  }

  static String? extractRoomIdFromUri(Uri uri) {
    // 1. Query parameter ?room=ALPHA-99
    if (uri.queryParameters.containsKey('room')) {
      return uri.queryParameters['room'];
    }
    // 2. Path parameter /room/ALPHA-99 or /join/ALPHA-99
    final pathSegments = uri.pathSegments;
    if (pathSegments.length >= 2 &&
        (pathSegments[0] == 'room' || pathSegments[0] == 'join')) {
      return pathSegments[1];
    }
    // 3. cocord://ALPHA-99
    if (uri.scheme == 'cocord' && uri.host.isNotEmpty && uri.host != 'join' && uri.host != 'room') {
      return uri.host;
    }
    return null;
  }

  void dispose() {
    _linkSub?.cancel();
  }
}

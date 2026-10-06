import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class RadioAudioManager extends ChangeNotifier {
  final AudioPlayer _boomboxPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isTransmitting = false;
  bool _isPlayingMusic = false;
  double _currentFrequency = 144.800;
  String _callsign = 'BRAVO-06';
  String _currentStation = 'Synthwave 24/7';
  double _boomboxVolume = 0.7;

  // Getters
  bool get isTransmitting => _isTransmitting;
  bool get isPlayingMusic => _isPlayingMusic;
  double get currentFrequency => _currentFrequency;
  String get callsign => _callsign;
  String get currentStation => _currentStation;
  double get boomboxVolume => _boomboxVolume;

  RadioAudioManager() {
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      
      _boomboxPlayer.playerStateStream.listen((state) {
        _isPlayingMusic = state.playing;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('[RadioAudio] AudioSession init error: $e');
    }
  }

  // Set tuned frequency
  void setFrequency(double freq) {
    _currentFrequency = double.parse(freq.toStringAsFixed(3));
    playSquelchBurst();
    notifyListeners();
  }

  void setCallsign(String newCallsign) {
    _callsign = newCallsign.toUpperCase();
    notifyListeners();
  }

  // Push to Talk (PTT)
  void startTransmitting() {
    if (_isTransmitting) return;
    _isTransmitting = true;
    
    // Auto-duck music
    _boomboxPlayer.setVolume(_boomboxVolume * 0.2);
    playSquelchBurst();
    notifyListeners();
  }

  void stopTransmitting() {
    if (!_isTransmitting) return;
    _isTransmitting = false;

    // Restore music
    _boomboxPlayer.setVolume(_boomboxVolume);
    playRogerBeep();
    notifyListeners();
  }

  // Synced Boombox Control
  Future<void> toggleMusic() async {
    if (_isPlayingMusic) {
      await _boomboxPlayer.pause();
    } else {
      try {
        await _boomboxPlayer.setUrl('https://stream.nightride.fm/nightride.m4a');
        await _boomboxPlayer.play();
      } catch (e) {
        debugPrint('[RadioAudio] Boombox stream error: $e');
      }
    }
    notifyListeners();
  }

  void setBoomboxVolume(double volume) {
    _boomboxVolume = volume;
    _boomboxPlayer.setVolume(_isTransmitting ? _boomboxVolume * 0.2 : _boomboxVolume);
    notifyListeners();
  }

  // Tactical SFX Simulation
  void playSquelchBurst() {
    debugPrint('[RadioAudio] Playing Squelch Burst SFX');
  }

  void playRogerBeep() {
    debugPrint('[RadioAudio] Playing Roger Beep Chirp SFX');
  }

  void playSoundboardDrop(String soundName) {
    debugPrint('[RadioAudio] Playing Soundboard Drop: $soundName');
  }

  @override
  void dispose() {
    _boomboxPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }
}

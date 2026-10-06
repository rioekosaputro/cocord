import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AppSettings {
  String callsign = 'BRAVO-06';
  double frequency = Freq.defaultFreq;
  bool volumeKeyPtt = true;
  bool rogerBeep = true;
  bool squelch = true;
  bool staticNoise = false;
  double staticVolume = 0.12;
  double boomboxVolume = 0.65;
  int station = 0;
  bool syncBoombox = true;

  /// Preferred audio devices, remembered by label (ids change between runs).
  String inputLabel = '';
  String outputLabel = '';

  /// Empty = use the built-in public broker list.
  String brokerHost = '';
  int brokerPort = 1883;
  String turnUrl = '';
  String turnUser = '';
  String turnPass = '';

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    final s = AppSettings();
    s.callsign = sanitizeCallsign(p.getString('callsign') ?? s.callsign);
    s.frequency = Freq.clamp(p.getDouble('frequency') ?? s.frequency);
    s.volumeKeyPtt = p.getBool('volumeKeyPtt') ?? s.volumeKeyPtt;
    s.rogerBeep = p.getBool('rogerBeep') ?? s.rogerBeep;
    s.squelch = p.getBool('squelch') ?? s.squelch;
    s.staticNoise = p.getBool('staticNoise') ?? s.staticNoise;
    s.staticVolume = p.getDouble('staticVolume') ?? s.staticVolume;
    s.boomboxVolume = p.getDouble('boomboxVolume') ?? s.boomboxVolume;
    s.station = (p.getInt('station') ?? 0).clamp(0, kStations.length - 1);
    s.syncBoombox = p.getBool('syncBoombox') ?? s.syncBoombox;
    s.inputLabel = p.getString('inputLabel') ?? '';
    s.outputLabel = p.getString('outputLabel') ?? '';
    s.brokerHost = p.getString('brokerHost') ?? '';
    s.brokerPort = p.getInt('brokerPort') ?? 1883;
    s.turnUrl = p.getString('turnUrl') ?? '';
    s.turnUser = p.getString('turnUser') ?? '';
    s.turnPass = p.getString('turnPass') ?? '';
    return s;
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('callsign', callsign);
    await p.setDouble('frequency', frequency);
    await p.setBool('volumeKeyPtt', volumeKeyPtt);
    await p.setBool('rogerBeep', rogerBeep);
    await p.setBool('squelch', squelch);
    await p.setBool('staticNoise', staticNoise);
    await p.setDouble('staticVolume', staticVolume);
    await p.setDouble('boomboxVolume', boomboxVolume);
    await p.setInt('station', station);
    await p.setBool('syncBoombox', syncBoombox);
    await p.setString('inputLabel', inputLabel);
    await p.setString('outputLabel', outputLabel);
    await p.setString('brokerHost', brokerHost);
    await p.setInt('brokerPort', brokerPort);
    await p.setString('turnUrl', turnUrl);
    await p.setString('turnUser', turnUser);
    await p.setString('turnPass', turnPass);
  }
}

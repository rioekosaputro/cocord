# 📻 FreqWave // Flutter Android Walkie-Talkie & Synced Boombox

A simple, clean, and modern Android Walkie-Talkie and Synchronized Music app built with Flutter.

---

## ✨ Features

- 📡 **Frequency Dialing**: Tune across virtual radio frequencies (e.g., `144.800 MHz`, `433.920 MHz`).
- 🎙️ **Hardware & Screen PTT**: Push-to-Talk via on-screen button or physical **Volume Down / Walkie-Talkie side keys**.
- 🎧 **Synchronized Boombox**: Listen to live music streams with friends on the same frequency.
- 📉 **Auto-Ducking**: Music volume automatically lowers by 70% whenever someone speaks on the frequency.
- 🔊 **Tactical Soundboard**: Instant audio drops (Roger Beep, Airhorn, Alert Siren, Morse SOS).
- 💬 **Squad Frequency Chat**: Real-time frequency room chat feed.

---

## 🚀 How to Run on Android

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0.0+)
- Android Studio / Android SDK with an Android device (Android 8.0+) or emulator.

### 2. Install Dependencies
```bash
cd freqwave_mobile
flutter pub get
```

### 3. Run on Device / Emulator
```bash
flutter run
```

---

## 📁 Project Structure

```
freqwave_mobile/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml   # Audio, background & bluetooth permissions
│       └── kotlin/.../MainActivity.kt # Volume Down / PTT hardware key intercept
├── lib/
│   ├── main.dart                 # App Entry point
│   ├── core/
│   │   ├── theme/tactical_theme.dart   # Clean Slate & Indigo Theme
│   │   └── audio/radio_audio_manager.dart # Audio focus, PTT, and auto-ducking
│   └── presentation/
│       ├── screens/tactical_radio_screen.dart # Main clean radio interface
│       └── widgets/
│           ├── rf_oscilloscope.dart     # Clean sine waveform visualizer
│           ├── ptt_button.dart          # Haptic PTT button
│           └── boombox_card.dart        # Synced music player card
└── pubspec.yaml
```

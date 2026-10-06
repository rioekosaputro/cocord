# Cocord Mobile

Walkie-talkie voice, frequency chat and a synced boombox for Android.
Everyone tuned to the same frequency (e.g. 144.800 MHz) is in the same room.

## Features

- **Voice (PTT)**: hold the on-screen button, the volume-down key or a hardware PTT key. Live WebRTC audio, full mesh (up to 8 radios per frequency). Optional open-mic.
- **Frequency tuning**: ±0.05 step, slider, type an exact value (88–999 MHz), presets, scanner that stops on activity.
- **Chat**: live text chat per frequency, join/leave notices, unread badge.
- **Synced boombox**: 4 internet radio stations; station and play/pause follow everyone on the frequency; music auto-ducks while anyone transmits.
- **Soundboard**: airhorn, siren, Morse SOS, etc. played locally and dropped on the frequency.
- **Radio sounds**: squelch bursts, roger beep, optional static (all synthesized on device, individually switchable).
- **Background**: foreground service keeps the radio alive with the screen off.
- **Listen-only mode** when the microphone permission is denied.

## How it works

- Presence, chat and WebRTC signaling go through a public MQTT broker (`broker.emqx.io`, falling back to HiveMQ / Mosquitto); voice goes peer-to-peer over WebRTC.
- **Privacy note:** frequencies are public rooms. Anyone who tunes to the same frequency can hear you and read chat. Pick an unusual frequency for private use, or set your own broker in *Settings → Advanced network*.
- Calls use STUN only by default. On some mobile carriers / strict NATs a TURN server is needed for voice; add yours in *Settings → Advanced network*.

## Build the ARM64 APK

```bat
build_apk_arm64.bat
```

or

```bash
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Output: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (Android 7.0+).

Release signing uses `android/key.properties` + `android/app/cocord-release.jks`
(git-ignored). **Back both up**: without them you can't ship updates over an installed app.

## Development

See [AGENTS.md](AGENTS.md) for structure, size limits and the definition of done.

```bash
flutter analyze
flutter test
flutter test tool/signaling_smoke_test.dart   # live broker check (needs internet)
```

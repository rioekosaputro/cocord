# Cocord Mobile

Voice rooms, chat and a synced music box for you and your friends. Android.

## Features

- **Rooms**: create or join a room by name. Add a password to make it private. Share an invite link that opens the app straight into the room (`cocord://join?...`).
- **Voice**: hold the big button (or the volume-down key) to talk, or switch on open mic. Live WebRTC audio, full mesh (up to 8 people per room).
- **Profile**: your own display name and avatar color; the speaking member lights up.
- **Chat**: live text chat per room with join/leave notices and an unread badge.
- **Boombox**: 4 internet radio stations; station and play/pause follow everyone in the room; music ducks while anyone talks.
- **Soundboard**: airhorn, siren, Morse SOS, etc. played locally and dropped in the room.
- **Audio devices**: pick your speaker and microphone (built-in, wired, Bluetooth); remembered.
- **Background**: a foreground service keeps you connected with the screen off.
- **Listen-only mode** when the microphone permission is denied.

## How it works

- Presence, chat and WebRTC signaling go through a public MQTT broker (`broker.emqx.io`, falling back to HiveMQ / Mosquitto); voice goes peer-to-peer over WebRTC.
- A room's network topic is a hash of its name **and** password. Without the password nobody can find or join a private room. Messages themselves are not end-to-end encrypted, so treat the public broker as semi-public.
- Public rooms (no password) can be joined by anyone who types the same name. The default room is `general`.
- Needs internet. STUN only by default; strict mobile carriers may need a TURN server (*Settings → Advanced network*). You can also point the app at your own MQTT broker there.

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

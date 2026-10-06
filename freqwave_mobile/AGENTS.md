# AGENTS.md — Cocord Mobile engineering rules

Rules for anyone (human or AI agent) changing this Flutter app. Follow them on every change. If a rule must be broken, explain why in the PR/commit message.

## 1. Size limits (hard)

| Unit | Limit |
|---|---|
| Method / function body | **40 lines** (aim for ≤ 25) |
| `build()` method of a widget | **60 lines** — split into private widgets, not helper methods |
| File | **300 lines** (aim for ≤ 200) |
| Class | **250 lines** |
| Method parameters | **5** (use a small config/options object beyond that) |
| Nesting depth | **3** levels (use early `return`, guard clauses, extracted methods) |
| Line length | **80** (`dart format` default) |

Blank lines and comments count. When a limit is exceeded, split by responsibility — never by arbitrary cut. Generated code is exempt.

## 2. Structure

```
lib/
  main.dart                 entry point only: init + runApp (≤ 40 lines)
  core/                     pure Dart + platform services, NO widgets
    models.dart             plain data classes / enums / constants
    settings.dart           persisted preferences
    synth.dart, sfx.dart    sound synthesis and playback
    signaling.dart          MQTT presence/chat/WebRTC signaling
    voice_mesh.dart         WebRTC audio mesh
    background_service.dart Android foreground service
    radio/                  RadioController split into focused parts
  ui/
    pages/                  one screen per file
    widgets/                reusable widgets, one public widget per file
    theme.dart              colors, text styles, ThemeData
test/                       mirrors lib/ one-to-one
```

- `core/` never imports `ui/`. `ui/` talks to `core/` only through `RadioController` (Provider).
- One public class per file (small private helpers allowed). File name = class name in `snake_case`.
- No circular imports. Import order: `dart:`, `package:flutter`, other packages, project (relative).
- New feature = new file(s) in the right folder, not more lines in an existing big file.

## 3. Code style

- `flutter analyze` must report **zero** issues; `dart format .` before finishing.
- Prefer `const` constructors/widgets; `final` over `var`; no `dynamic` unless decoding JSON, and validate immediately.
- No magic numbers/strings: name them as `const` (timeouts, limits, topics, durations).
- Names say what, not how: `startTransmit()`, not `doPtt()`. Booleans read as questions: `isJoined`, `hasMic`.
- Comments explain *why*, never restate *what*. Public API gets a one-line `///` doc.
- No commented-out code, no `print` (use `debugPrint` guarded by a `[Tag]` prefix), no TODOs without an owner/issue.
- Prefer composition over inheritance; prefer immutable data.

## 4. State & architecture

- UI is dumb: widgets render state and forward events. No networking, audio or timers in widgets.
- `RadioController` (ChangeNotifier) is the single source of truth. Its parts live in `core/radio/` as focused mixins/services (session, ptt, chat, boombox, scanner…), each ≤ 300 lines.
- Call `notifyListeners()` once per state change batch, not in loops. Use `context.select` for fine-grained rebuilds.
- Every `Timer`, `StreamSubscription`, `AudioPlayer`, `RTCPeerConnection`, `MediaStream` has an owner and is cancelled/disposed in `dispose()`/`leave()`.
- All async calls that can fail are wrapped; failures surface as a user-visible message or a `debugPrint`, never a silent crash.

## 5. Networking & security

- Treat every incoming MQTT/WebRTC payload as hostile: validate type, length and allowed values; cap chat text (500), callsign (12), payload size (24 KB); rate-limit remote soundboard triggers.
- Never log message contents, SDP, credentials or TURN secrets.
- Secrets (keystore, `key.properties`, TURN passwords) are never committed; they are git-ignored.
- Protocol changes bump the topic version (`cocord/v1` → `v2`) and stay backward-safe for one release.

## 6. Android

- Application id / namespace: `com.cocord.app` — do not change it (breaks updates).
- Runtime permissions are requested at the moment of need, with a clear explanation, and denial must degrade gracefully (listen-only mode without mic).
- Foreground service types in the manifest must match the permissions requested.
- Release builds are signed with `android/key.properties`; **back up the keystore** — losing it means users can't update.
- Keep `minSdk` compatible with the oldest supported device (API 24+); test on it before release.

## 7. Testing & verification

- Every bug fix gets a regression test; every new pure-Dart unit (models, synth, message validation, scanner logic) gets a unit test.
- Widget tests cover each page's primary interactions; tests must not touch the network or real audio (inject fakes).
- Before finishing a change: `flutter analyze` → `flutter test` → `flutter build apk --release --target-platform android-arm64 --split-per-abi`.
- Voice/PTT changes must be checked on two real devices (or device + emulator) on the same frequency.

## 8. Dependencies

- Add a package only if it saves substantial code and is actively maintained; justify in the commit message.
- Pin with caret ranges, commit `pubspec.lock`, run `flutter pub outdated` each release.
- No runtime font/asset downloads — the app must start fully offline.

## 9. Git & releases

- Small, focused commits; message format `area: what changed` (e.g. `ptt: release mic after 150 ms tail`).
- Bump `version:` in `pubspec.yaml` for every released APK (`1.0.0+1` → build number always increases).
- Build with `build_apk_arm64.bat`; output: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.

## 10. Definition of done

A change is done only when: limits in §1 respected, analyzer clean, tests pass, release APK builds, no new warnings, and README/AGENTS.md updated if behavior or structure changed.

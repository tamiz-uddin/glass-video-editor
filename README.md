# Glass Video Editor

A premium, glassmorphism-styled mobile video editor for Android and iOS, built with Flutter and a native video engine (Media3 on Android, AVFoundation on iOS).

## Stack

- **UI:** Flutter (Impeller renderer) — 120fps smooth, hardware-accelerated
- **State:** Riverpod
- **Local storage:** Hive
- **Video preview:** `video_player`
- **Video engine (native bridge):** MethodChannel `com.glass.videoeditor/video_engine`
  - Android: Media3 (`ExoPlayer` preview, `Transformer` export) + FFmpeg for filters/effects
  - iOS: AVFoundation (`AVVideoComposition` export)
- **ML (planned):** MediaPipe / ML Kit — background removal, motion tracking, face detection

## Architecture

```
lib/
  main.dart                     entry, Hive init
  app.dart                      MaterialApp + theme
  core/
    theme/app_theme.dart        colors, gradient, radius, dark theme
    widgets/glass_panel.dart    reusable frosted-glass container (BackdropFilter)
    models/                     Project, Clip + Hive adapters
    video/video_engine.dart     MethodChannel bridge to native engine
  features/
    home/home_screen.dart       project list, new project flow
    projects/projects_provider.dart
    editor/
      editor_screen.dart        preview + toolbar + timeline layout
      widgets/editor_preview.dart
      widgets/glass_toolbar.dart
      widgets/glass_timeline.dart
```

## Design system (fluid glassmorphism)

- Background `#0A0A0F`, glass panels `white @ 6–12%` with `ImageFilter.blur` (sigma 20–30)
- 1px border `white @ 15%`, radius 20px panels / 14px buttons
- Accent gradient violet `#8B5CF6` → cyan `#22D3EE`
- Spring/easeOut animations via `flutter_animate`, Hero-style fade/slide page transitions

## Setup

```bash
flutter pub get
flutter run
```

Platform folders are minimal stubs; to regenerate full native projects:

```bash
flutter create --platforms android,ios .
```

## Roadmap

1. **Phase 1 (MVP):** import, multi-track timeline, trim/split, speed, volume, text, basic filters, music, 1080p export
2. **Phase 2:** keyframes, transitions, chroma key, stabilization, stickers, auto captions, beat sync
3. **Phase 3:** motion tracking, AI background removal, TTS, templates, cloud sync
4. **Phase 4:** AI generation/upscale (cloud), team collaboration, 4K60 export

## Notes

- All assets (templates, music, stickers) must be original or royalty-free — do not copy third-party app assets.
- The native `export`/`probeDuration` handlers are stubs; wire them to Media3 Transformer / AVFoundation next.

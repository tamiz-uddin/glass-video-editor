# Glass Video Editor (Android)

A premium, glassmorphism-styled Android video editor built with Flutter and a native Media3 video engine.

## Stack

- **UI:** Flutter (Impeller renderer) — smooth 120fps, hardware-accelerated
- **State:** Riverpod; **local storage:** Hive
- **Preview:** `video_player` (ExoPlayer on Android)
- **Export engine (native Kotlin):** Media3 `Transformer` + `Composition` — trim/concat multi-clip timelines, text overlays, H.264 MP4 export with progress events
- **ML (planned):** MediaPipe / ML Kit — background removal, motion tracking

## Architecture

```
lib/
  main.dart                       entry, Hive init + adapters
  app.dart                        MaterialApp + dark theme
  core/
    theme/app_theme.dart          colors, accent gradient, radii, theme
    widgets/glass_panel.dart      reusable frosted-glass panel (BackdropFilter)
    models/                       Project, Clip, TextOverlay + Hive adapters
    video/video_engine.dart       MethodChannel/EventChannel bridge
  features/
    home/home_screen.dart         project list, multi-video import
    projects/projects_provider.dart
    editor/
      editor_controller.dart      all timeline ops + persistence
      timeline_math.dart          pure functions: split/trim/reorder/speed (unit-tested)
      editor_screen.dart          preview + toolbar + timeline + export flow
      widgets/  preview, glass timeline (reorder + trim handles + playhead), toolbar, tool sheets
android/app/src/main/kotlin/com/glass/videoeditor/
  MainActivity.kt                 pickVideos (SAF), channel + progress wiring
  VideoEngine.kt                  MediaExtractor probe, Media3 Transformer export
test/timeline_math_test.dart      unit tests for timeline math
```

## Implemented

- Multi-video import (SAF picker, persistable URI permissions), duration probing via MediaExtractor
- Projects persisted in Hive (clips, text overlays, export settings)
- Timeline: reorder (drag), select, split at playhead, trim handles, seek ruler, playhead
- Per-clip speed (0.1x–10x) and volume; preview applies trim/speed/volume and auto-advances across clips
- Text overlays on timeline; rendered in preview and burned into export (StaticOverlay)
- Export: 720p / 1080p / 4K portrait, 24/30/60 fps, live progress via EventChannel, output to app-specific external dir
- Glassmorphism UI: blurred floating panels over preview, gradient accents, spring animations

## Remaining roadmap

1. Filters/effects & transitions (FFmpeg or media3 effects), chroma key (GPU shader)
2. Stabilization (gyro/OpenCV), motion tracking (MediaPipe), beat sync (FFT), auto captions (Whisper)
3. Speed change in export (FFmpeg post-process), background removal, templates, cloud sync

## Setup

```bash
flutter pub get
flutter test          # timeline math unit tests
flutter run           # Android device/emulator
```

Note: all media/templates used must be original or royalty-free.

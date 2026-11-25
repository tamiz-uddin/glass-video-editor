# Production Plan — Glass Video Editor (Android)

Goal: ship a production-ready, Play-Store-publishable Android video editor with the full feature set, solo-developer friendly, ~6 months.

---

## 1. Feature inventory → implementation mapping

| Feature | Status | Implementation |
|---|---|---|
| Import videos/photos (multi) | done | SAF picker, MediaExtractor probe |
| Multi-track timeline, reorder, trim, split, delete | done | `timeline_math.dart`, glass timeline widget |
| Speed 0.1x–100x + curves | preview done | Preview: `setPlaybackSpeed`. Export: FFmpeg `setpts` post-process |
| Volume / fade | preview done | Export: FFmpeg `afade` |
| Reverse, freeze frame | planned | FFmpeg `reverse` / single-frame hold |
| Crop / zoom-pan / rotate / flip | planned | media3 `Presentation`/`ScaleAndRotateTransformation` or FFmpeg |
| Keyframe animation | planned | Dart animation engine (interpolators) → baked into export via per-frame transform (FFmpeg `zoompan`/`overlay`) |
| Optical-flow slow-mo | planned | FFmpeg `minterpolate` |
| Chroma key | planned | GPU shader in preview; FFmpeg `colorkey` in export |
| Stabilization | planned | Gyro data + OpenCV `videostab` |
| Motion tracking | planned | MediaPipe object tracking → keyframe path |
| Auto captions + translation | planned | On-device Whisper.cpp (small model) with cloud fallback |
| Background removal | planned | MediaPipe selfie/body segmentation (on-device) |
| Text-to-speech | planned | Cloud TTS via server proxy (Play Billing gated) |
| AI generation / upscale / denoise | planned | Cloud APIs behind Firebase Cloud Functions proxy (keys never in app) |
| Templates | planned | JSON-driven templates + own royalty-free asset pack |
| Filters / transitions / effects | planned | LUTs + GPU shaders (preview), FFmpeg filters (export) |
| Music library + SFX + beat sync | planned | Royalty-free bundled pack + FFT beat detection (on-device) |
| Text & stickers (animated) | partial | Text done; animated stickers via overlay tracks |
| Export 720p–4K, 24–60fps, HDR | partial | Media3 Transformer; 4K60 needs hardware encoder check |
| Cloud storage, drafts sync, team editing | planned | Firebase Firestore + Cloud Storage; simple lock-based collaboration |
| Pro / monetization | planned | Play Billing subscriptions |

---

## 2. Architecture

Clean-layers Flutter app, feature-first:

```
lib/
  core/        theme, widgets, models, utils, constants
  data/        hive adapters, repositories (project_repo, media_repo, settings_repo)
  features/    home, editor, export, templates, ai, settings, paywall
  app.dart     go_router routes, DI (Riverpod providers)
```

- State: Riverpod (controllers per feature, keep UI dumb)
- Navigation: `go_router` (deep links for shared projects)
- Background work: `workmanager` for exports; foreground service notification during export
- Heavy work (thumbnails, waveform, beat detection) in Dart `Isolate`s / compute()
- Native: single `VideoEngine` (MethodChannel) → Kotlin `Media3Engine` + `FfmpegEngine` classes; progress via EventChannel

## 3. Export pipeline (production-grade)

1. User taps Export → enqueue job (Hive queue, survives process death)
2. WorkManager starts foreground worker → builds FFmpeg/Media3 command from project JSON
3. Progress via EventChannel → Riverpod → UI progress ring
4. Retry with backoff on failure; thermal watchdog pauses if device hot
5. Output to `Android/media/` (MediaStore) + share sheet; auto-cleanup of cache > 500MB

## 4. Data & sync

- Local: Hive boxes (projects, clips, overlays, queue, settings)
- Remote: Firestore (project metadata, locks), Cloud Storage (media, exports)
- Auth: Firebase Auth (Google + anonymous)
- Conflict strategy: per-project lock (Firestore transaction); last-write-wins with version field

## 5. Phases & estimates (solo)

| Phase | Scope | Est. |
|---|---|---|
| 0 — Hardening | compile fixes, `flutter test` green, CI, crash reporting, logging | 1–2 wk |
| 1 — Core editor complete | transitions, filters, stickers, music, captions (manual), export speed/fade/reverse, thumbnails, waveform | 4–6 wk |
| 2 — AI features | auto captions, background removal, TTS, upscale/denoise (cloud proxy) | 3–4 wk |
| 3 — Advanced editing | keyframes, chroma key, stabilization, motion tracking, slow-mo, beat sync | 6–8 wk |
| 4 — Platform & business | templates marketplace, cloud sync, collaboration, Play Billing Pro | 4–6 wk |
| 5 — Polish & launch | performance, a11y, i18n (bn/en), onboarding, privacy policy, store listing, staged rollout | 3–4 wk |

## 6. Testing strategy

- Unit: timeline math, export command builder, beat detection (done: timeline tests)
- Widget: timeline interactions, tool sheets (golden tests for glass UI)
- Integration: `integration_test` — import → edit → export on emulator
- Device farm: Firebase Test Lab (Pixel + low-end device) in CI
- Manual checklist per release

## 7. Performance budgets

- Timeline scroll & preview: 60fps on mid-range (Snapdragon 6-series)
- Cold start < 2.5s; editor open < 1s
- Export 1080p30 10s clip: < 2x realtime on mid-range
- Initial APK < 60MB (AAB with per-ABI splits); FFmpeg .so per-ABI
- Crash-free sessions > 99.5%, ANR < 0.1%

## 8. Security & privacy

- No API keys in app — Cloud Functions proxy with rate limits
- Secrets via `--dart-define` + CI secrets, never committed
- EncryptedSharedPreferences for tokens; scoped storage only (no legacy storage perms beyond 32)
- Privacy policy + Play Data Safety form; delete-account flow; media never uploaded without explicit sync opt-in
- R8/ProGuard rules for media3 + MLKit + reflection-based libs

## 9. CI/CD (GitHub Actions)

- On PR/push: `flutter analyze`, `flutter test`, build debug APK (artifact)
- On tag `v*`: build signed release AAB, upload to Play (via `rickclephas/upload-to-play-store` or manual)
- Branch protection on `main`; PR template required

## 10. Observability

- Firebase Crashlytics + Analytics (events: export_started/completed/failed, feature usage)
- Structured logging (debug only), remote log drain on crashes

## 11. Store & legal checklist

- Play Console account ($25), app bundle, 64-bit, targetSdk 35
- Screenshots + feature graphic (bn/en), short/long description
- Privacy policy URL, Data Safety, content rating, ads declaration (if AdMob)
- Signed release keystore stored in CI secrets / password manager, backup kept
- Staged rollout 10% → 50% → 100%, monitor crash dashboard

## 12. Cost estimate (monthly, at modest usage)

- Firebase Blaze: ~$10–50
- Cloud Functions + AI APIs (captions/upscale/TTS): ~$20–200 depending on usage
- Play Console: $25 one-time
- Domain + privacy policy hosting: ~$12/yr

## 13. Top risks

- FFmpeg binary size/perf on low-end devices → per-ABI, fallback to Media3-only pipeline
- AI API cost abuse → server-side rate limits + Pro gating
- Export thermal throttling → foreground service + pause/resume
- Asset licensing (templates/music) → only original/royalty-free packs

## 14. Definition of done (launch)

All Phase 0–5 items checked, CI green, crash-free > 99.5% in Test Lab, store listing live, staged rollout started.

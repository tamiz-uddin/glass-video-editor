import 'package:glass_video_editor/core/models/clip.dart';

const int minClipMs = 100;

int totalDurationMs(List<Clip> clips) =>
    clips.fold(0, (sum, c) => sum + c.effectiveDurationMs);

int timelineStartOf(List<Clip> clips, String clipId) {
  var acc = 0;
  for (final c in clips) {
    if (c.id == clipId) return acc;
    acc += c.effectiveDurationMs;
  }
  return -1;
}

int clipIndexAt(List<Clip> clips, int timelineMs) {
  var acc = 0;
  for (var i = 0; i < clips.length; i++) {
    acc += clips[i].effectiveDurationMs;
    if (timelineMs < acc) return i;
  }
  return clips.isEmpty ? -1 : clips.length - 1;
}

Clip clampTrim(Clip clip, int newStartMs, int newEndMs) {
  final end = clip.sourceEndMs;
  final start = newStartMs.clamp(0, end - minClipMs);
  final stop = newEndMs.clamp(start + minClipMs, end);
  return clip.copyWith(trimStartMs: start, trimEndMs: stop);
}

List<Clip> splitClipInList(List<Clip> clips, String clipId, int offsetMs) {
  final index = clips.indexWhere((c) => c.id == clipId);
  if (index < 0) return clips;
  final clip = clips[index];
  final sourcePos = clip.trimStartMs + (offsetMs * clip.speed).round();
  final cut = sourcePos.clamp(clip.trimStartMs + minClipMs, clip.sourceEndMs - minClipMs);
  final left = clip.copyWith(trimEndMs: cut);
  final right = clip.copyWith(
    id: '${clip.id}_r',
    trimStartMs: cut,
    trimEndMs: clip.trimEndMs,
  );
  return [...clips.sublist(0, index), left, right, ...clips.sublist(index + 1)];
}

List<Clip> reorderClips(List<Clip> clips, int from, int to) {
  final list = List<Clip>.of(clips);
  final item = list.removeAt(from);
  list.insert(to, item);
  return list;
}

Clip setSpeed(Clip clip, double speed) =>
    clip.copyWith(speed: speed.clamp(0.1, 100.0));

Clip setVolume(Clip clip, double volume) =>
    clip.copyWith(volume: volume.clamp(0.0, 1.0));
